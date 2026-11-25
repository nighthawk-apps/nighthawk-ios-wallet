//
//  Chat+Connection.swift
//  Home
//
//  Connection lifecycle, tunnel polling, and FUD offer policy handling for Chat.
//

import ComposableArchitecture
import DarkfiCore
import Foundation
import Models
import SwiftUI

extension Chat {
    /// Adapts UniFFI `DarkircEventCallback` into an `AsyncStream`.
    final class ChatEventRelay: DarkircEventCallback, @unchecked Sendable {
        let continuation: AsyncStream<State.Message>.Continuation
        let myNickname: String

        init(continuation: AsyncStream<State.Message>.Continuation, myNickname: String = "anon") {
            self.continuation = continuation
            self.myNickname = myNickname
        }

        deinit {
            continuation.finish()
        }

        func finish() {
            continuation.finish()
        }

        static func makeStream(myNickname: String) -> (AsyncStream<State.Message>, ChatEventRelay) {
            let (stream, continuation) = AsyncStream<State.Message>.makeStream()
            return (stream, ChatEventRelay(continuation: continuation, myNickname: myNickname))
        }

        // Signature fixed by generated UniFFI `DarkircEventCallback` protocol.
        // swiftlint:disable:next function_parameter_count
        func onMessage(
            eventId: String,
            channel: String,
            nick: String,
            message: String,
            timestamp: UInt64,
            isOutgoing: Bool
        ) {
            let msg = State.Message(
                id: eventId,
                sender: nick,
                content: message,
                channel: channel,
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000),
                isOutgoing: isOutgoing
            )
            continuation.yield(msg)
        }
    }

    func handleConnect(state: inout State) -> Effect<Action> {
        state.connectionState = .startingDaemon
        state.diagnosticDetail = nil
        state.dagSyncCount = 0
        restoreChatHistoryIfEmpty(&state)
        state.privacyNetwork = SessionPrivacyOverride.resolved(
            stored: userStoredPreferences.walletPrivacyNetwork()
        )
        let config = DaemonConnectionConfig(
            nickname: state.nickname,
            network: state.privacyNetwork,
            torPort: UInt16(userStoredPreferences.torSocksPort() ?? "") ?? 9050,
            useEmbeddedTor: userStoredPreferences.useEmbeddedTor(),
            dagsCount: UInt32(max(1, userStoredPreferences.darkircDagsCount())),
            fastMode: userStoredPreferences.darkircFastMode()
        )

        return .run { send in
            await runDaemonConnection(send: send, config: config)
        }
        .cancellable(id: CancelID.connection, cancelInFlight: true)
    }

    private struct DaemonConnectionConfig: Sendable {
        let nickname: String
        let network: NighthawkSetting.PrivacyNetwork
        let torPort: UInt16
        let useEmbeddedTor: Bool
        let dagsCount: UInt32
        let fastMode: Bool
    }

    private func runDaemonConnection(
        send: Send<Action>,
        config: DaemonConnectionConfig
    ) async {
        let daemon = DarkircDaemonManager.shared
        await send(.embeddedNodeStatusChanged(.starting))
        await send(.dagSyncStatusUpdate("Starting darkirc node…"))

        let (stream, relay) = ChatEventRelay.makeStream(myNickname: config.nickname)

        guard await ensurePrivacyTunnel(send: send, relay: relay, config: config) else {
            return
        }

        let transport: DarkircTransport = switch config.network {
        case .nym: .nym
        case .tor: .tor
        case .direct: .direct
        }
        let socksPort: UInt16 = config.network == .tor ? config.torPort : NighthawkSetting.PrivacyNetwork.nymSocksPort

        do {
            configureDarkirc(dagsCount: config.dagsCount, fastMode: config.fastMode)
            try await daemon.restartForChat(callback: relay, transport: transport, socksPort: socksPort)
        } catch {
            relay.finish()
            await send(.ircBridgeError(error.localizedDescription))
            await send(.connectionStateChanged(.error))
            await send(.embeddedNodeStatusChanged(.failed))
            return
        }

        await send(.connectionStateChanged(.waitingForDagSync))
        await send(.dagSyncStatusUpdate("Waiting for P2P peers…"))

        guard await awaitDagConnected(send: send, relay: relay) else {
            return
        }

        await send(.embeddedNodeStatusChanged(.ready))
        let connected: State.ConnectionState = switch config.network {
        case .nym: .connectedViaNym
        case .tor: .connectedViaTor
        case .direct: .connectedDirect
        }
        await send(.connectionStateChanged(connected))
        await send(.dagSyncStatusUpdate(nil))

        for await msg in stream {
            await send(.messageReceived(msg))
        }

        await send(.connectionStateChanged(.disconnected))
        await send(.embeddedNodeStatusChanged(.notUsed))
    }

    private func ensurePrivacyTunnel(
        send: Send<Action>,
        relay: ChatEventRelay,
        config: DaemonConnectionConfig
    ) async -> Bool {
        if config.network == .nym {
            await send(.dagSyncStatusUpdate("Waiting for the Nym mixnet…"))
            let ready = await waitForNymTunnel()
            if !ready {
                relay.finish()
                await send(.ircBridgeError("Nym mixnet is not up"))
                await send(.connectionStateChanged(.error))
                await send(.embeddedNodeStatusChanged(.failed))
                return false
            }
        } else if config.network == .tor, config.useEmbeddedTor {
            await send(.dagSyncStatusUpdate("Waiting for Tor (Arti)…"))
            let ready = await waitForArtiTunnel(port: config.torPort)
            if !ready {
                relay.finish()
                await send(.ircBridgeError("Tor (Arti) is not up"))
                await send(.connectionStateChanged(.error))
                await send(.embeddedNodeStatusChanged(.failed))
                return false
            }
        }
        return true
    }

    private func awaitDagConnected(send: Send<Action>, relay: ChatEventRelay) async -> Bool {
        var pollCount = 0
        let maxPolls = 90
        while pollCount < maxPolls {
            guard !Task.isCancelled else {
                relay.finish()
                return false
            }
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                relay.finish()
                return false
            }
            guard !Task.isCancelled else {
                relay.finish()
                return false
            }
            pollCount += 1
            let ffiStatus = darkircStatus()
            let ffiPhase = darkircConnectionPhase()

            switch ffiStatus {
            case "failed":
                relay.finish()
                await send(.ircBridgeError("darkirc daemon failed during startup"))
                await send(.connectionStateChanged(.error))
                await send(.embeddedNodeStatusChanged(.failed))
                return false
            case "running":
                if ffiPhase == "connected" {
                    await send(.embeddedNodeStatusChanged(.ready))
                    return true
                } else if ffiPhase == "waiting_for_peers" {
                    await send(.embeddedNodeStatusChanged(.waitingForPeers))
                    await send(.dagSyncStatusUpdate("Waiting for P2P peers… (\(pollCount)s)"))
                } else {
                    await send(.embeddedNodeStatusChanged(.syncingDag))
                    await send(.dagSyncStatusUpdate("DAG syncing (\(ffiPhase))… (\(pollCount)s)"))
                }
            case "starting":
                await send(.embeddedNodeStatusChanged(.starting))
                await send(.dagSyncStatusUpdate("Starting embedded node… (\(pollCount)s)"))
            default:
                break
            }
        }

        relay.finish()
        let diag = "darkirc did not finish DAG sync (status: \(darkircStatus()), phase: \(darkircConnectionPhase()))"
        await send(.ircBridgeError(diag))
        await send(.connectionStateChanged(.error))
        await send(.embeddedNodeStatusChanged(.failed))
        return false
    }

    func handleConnectionStateChanged(_ newState: State.ConnectionState, state: inout State) -> Effect<Action> {
        state.connectionState = newState
        if newState.isConnected, state.selectedChannel == nil,
           let first = state.channels.first {
            let previous = state.composerKey
            state.selectedChannel = first
            state.messages = IdentifiedArrayOf(
                uniqueElements: state.channelMessages[first.name] ?? []
            )
            state.moveComposer(from: previous)
        }
        if case .error = newState {
            let existing = state.diagnosticDetail?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existing.isEmpty {
                state.diagnosticDetail = """
                    Could not start the embedded darkirc node. Rebuild the Rust FFI with \
                    ./scripts/build-darkfi-mobile-ffi-ios.sh, then try Connect again. \
                    If it persists, check the Xcode console for P2P/DAG errors.
                    """
            }
        } else {
            state.diagnosticDetail = nil
        }
        guard newState.isConnected else { return .none }
        let nick = state.nickname
        return .run { send in
            await DarkircCryptoStore.shared.registerAllWithRust()
            let pending = await ChatOutboxStore.shared.loadAll()
            for record in pending {
                await ChatOutboxStore.shared.updateDelivery(id: record.id, delivery: "sending")
                do {
                    try sendChatMessage(channel: record.channel, nick: nick, message: record.text)
                    await ChatOutboxStore.shared.remove(id: record.id)
                    await send(.markOutgoingSent(id: record.id, channel: record.channel))
                } catch {
                    await ChatOutboxStore.shared.updateDelivery(id: record.id, delivery: "failed")
                    await send(.markOutgoingFailed(id: record.id, channel: record.channel))
                }
            }
        }
    }

    func handleFudOffer(raw: String, meshOn: Bool, state: inout State) -> Effect<Action> {
        let uri = FudUri.parse(raw) ?? FudUri.find(in: raw)
        let privateTransport =
            state.connectionState == .connectedViaTor ||
            state.connectionState == .connectedViaNym
        switch FudTransferPolicy.decide(
            enabled: FudPreferences.isEnabled(),
            privateTransport: privateTransport,
            meshOn: meshOn,
            uri: uri
        ) {
        case .allowed:
            if let uri {
                do {
                    _ = try FudOfferInbox.queue(uri: uri)
                    state.fudNotice = "Queued \(uri.displayName). The offer is saved on this phone; the file is not downloaded yet."
                } catch {
                    state.fudNotice = "Could not queue the file offer."
                }
            }
        case .disabled:
            state.fudNotice = "File offers are off. Turn them on in Chat settings."
        case .needsPrivateTransport:
            state.fudNotice = "File offers need Nym, Tor, or nearby mesh. Clearnet is rejected."
        case .invalid:
            state.fudNotice = "That file offer is not a valid fud:// link."
        }
        return .none
    }
}

/// Poll until the in-process Nym tunnel reports ready, or the native bootstrap fails.
func waitForNymTunnel() async -> Bool {
    if DarkfiFfiSafe.isNymRunning() { return true }
    _ = DarkfiFfiSafe.startNymProxySafely(socksPort: NighthawkSetting.PrivacyNetwork.nymSocksPort)
    for _ in 0..<240 {
        guard !Task.isCancelled else { return false }
        if DarkfiFfiSafe.isNymRunning() { return true }
        if DarkfiFfiSafe.nymStatus() == "failed" { return false }
        do {
            try await Task.sleep(for: .milliseconds(500))
        } catch {
            return false
        }
    }
    return DarkfiFfiSafe.isNymRunning()
}

/// Poll until the in-process Tor (Arti) proxy reports ready.
func waitForArtiTunnel(port: UInt16) async -> Bool {
    if DarkfiFfiSafe.isArtiRunning() { return true }
    _ = DarkfiFfiSafe.startArtiProxySafely(socksPort: port)
    for _ in 0..<120 {
        guard !Task.isCancelled else { return false }
        if DarkfiFfiSafe.isArtiRunning() { return true }
        do {
            try await Task.sleep(for: .milliseconds(500))
        } catch {
            return false
        }
    }
    return DarkfiFfiSafe.isArtiRunning()
}
