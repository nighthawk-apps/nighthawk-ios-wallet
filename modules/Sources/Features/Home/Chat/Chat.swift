//
//  Chat.swift
//  stealth
//
//  DarkFi IRC chat — connects to embedded darkirc via local IRC bridge.
//  All P2P/event-graph work is done by darkirc; this layer is a TCP IRC
//  client that JOINs channels and reads PRIVMSG lines.
//

import ComposableArchitecture
import Foundation
import Generated
import Models
import SwiftUI
import UIKit
import UserPreferencesStorage
import Utils
import DarkfiCore

// swiftlint:disable type_body_length
@Reducer
public struct Chat {
    @ObservableState
    public struct State: Equatable {
        /// Connection state matching Android DarkfiChatConnectionState.
        public enum ConnectionState: Equatable {
            case disconnected
            case connecting
            case startingDaemon
            case waitingForDagSync
            case connectedDirect
            case connectedViaTor
            case connectedViaNym
            case degraded
            case error

            public var isConnected: Bool {
                switch self {
                case .connectedDirect, .connectedViaTor, .connectedViaNym:
                    return true
                default:
                    return false
                }
            }

            public var label: String {
                switch self {
                case .disconnected: return "Disconnected"
                case .connecting: return "Connecting to IRC…"
                case .startingDaemon: return "Starting darkirc node…"
                case .waitingForDagSync: return "Syncing event graph…"
                case .connectedDirect: return "Connected (direct)"
                case .connectedViaTor: return "Connected (Tor)"
                case .connectedViaNym: return "Connected (Nym)"
                case .degraded: return "Degraded"
                case .error: return "Error"
                }
            }

            public var indicatorColor: String {
                switch self {
                case .connectedDirect, .connectedViaTor, .connectedViaNym: return "green"
                case .connecting, .startingDaemon, .waitingForDagSync, .degraded: return "yellow"
                case .disconnected, .error: return "red"
                }
            }
        }

        /// Embedded darkirc node status matching Android EmbeddedDarkircNodeStatus.
        public enum EmbeddedNodeStatus: Equatable {
            case notUsed
            case starting
            case running
            case waitingForPeers
            case syncingDag
            case ready
            case missingBinary
            case failed

            public var label: String {
                switch self {
                case .notUsed: return "Not used"
                case .starting: return "Starting…"
                case .running: return "Running"
                case .waitingForPeers: return "Finding peers…"
                case .syncingDag: return "Syncing DAG…"
                case .ready: return "Ready"
                case .missingBinary: return "Missing binary"
                case .failed: return "Failed"
                }
            }
        }

        public struct Message: Equatable, Identifiable {
            public let id: String
            public let sender: String
            public let content: String
            public let channel: String
            public let timestamp: Date
            public let isOutgoing: Bool
            public let failedToDecrypt: Bool

            public init(
                id: String = UUID().uuidString,
                sender: String,
                content: String,
                channel: String = "",
                timestamp: Date = Date(),
                isOutgoing: Bool = false,
                failedToDecrypt: Bool = false
            ) {
                self.id = id
                self.sender = sender
                self.content = content
                self.channel = channel
                self.timestamp = timestamp
                self.isOutgoing = isOutgoing
                self.failedToDecrypt = failedToDecrypt
            }
        }

        public struct Channel: Equatable, Identifiable, Hashable {
            public let id: String
            public let name: String
            public let topic: String
            public var unreadCount: Int

            public init(
                id: String? = nil,
                name: String,
                topic: String = "",
                unreadCount: Int = 0
            ) {
                self.id = id ?? name
                self.name = name
                self.topic = topic
                self.unreadCount = unreadCount
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
        }

        public var channels: IdentifiedArrayOf<Channel> = []
        public var selectedChannel: Channel?
        public var messages: IdentifiedArrayOf<Message> = []
        /// All messages keyed by channel name
        public var channelMessages: [String: [Message]] = [:]
        public var composedMessage: String = ""
        /// Per-room composer text. Keys are `ch:<channel id>` and `dm:<contact id>`.
        public var composerDrafts: [String: String] = [:]

        /// Active composer slot. Channel and DM text must not share one buffer.
        public var composerKey: String {
            if selectedTab == .direct {
                return "dm:\(selectedDmContact?.id ?? "")"
            }
            return "ch:\(selectedChannel?.id ?? "")"
        }

        mutating func moveComposer(from previous: String) {
            let next = composerKey
            guard previous != next else { return }
            if composedMessage.isEmpty {
                composerDrafts.removeValue(forKey: previous)
            } else {
                composerDrafts[previous] = composedMessage
            }
            composedMessage = composerDrafts[next] ?? ""
        }
        public var connectionState: ConnectionState = .disconnected
        public var fudNotice: String?
        public var embeddedNodeStatus: EmbeddedNodeStatus = .notUsed
        public var diagnosticDetail: String?
        /// Persistent hawkXXX nickname — generated once, persists between sessions.
        public var nickname: String = DarkfiChatDefaults.persistentNickname()
        /// DarkFi receive address, filled by Home when the wallet loads it.
        public var receiveAddress: String = ""
        /// Lightwalletd tip, shown in the connection drawer.
        public var chainTip: Int = 0
        /// Lightwalletd status message (includes stale-tip warnings).
        public var lightStatusMessage: String?
        public var privacyNetwork: NighthawkSetting.PrivacyNetwork = .default
        /// Number of DAG bootstrap messages received
        public var dagSyncCount: Int = 0
        /// Descriptive string for DAG sync progress (e.g. "Syncing DAG… 142 events")
        public var dagSyncProgress: String?
        /// Event IDs already delivered to the UI — prevents duplicate rendering.
        public var seenEventIds: Set<String> = []

        // MARK: - DM state

        /// Channels vs Direct tab selection
        public enum ChatTab: String, Equatable, CaseIterable {
            case channels = "Channels"
            case direct = "Direct"
        }

        public var selectedTab: ChatTab = .channels
        public var dmContacts: [DmContact] = []
        public var dmConversations: [DmConversation] = []
        public var selectedDmContact: DmContact?
        /// DM messages keyed by contact ID
        public var dmMessages: [String: [Message]] = [:]
        /// Show the new DM conversation sheet
        @Presents public var newDmConversation: NewDmConversation.State?
        /// Show share-my-pubkey warning alert
        public var showSharePubkeyWarning: Bool = false
        public var myDmPublicKey: String?

        public init() {
            // Fresh defaults: `#nighthawk` first and selected (Android/desktop parity).
            let defaults = DarkfiChatDefaults.defaultPublicChannels.map { name in
                Channel(
                    name: name,
                    topic: DarkfiChatDefaults.defaultChannelTopics[name] ?? ""
                )
            }
            self.channels = IdentifiedArrayOf(uniqueElements: defaults)
            self.selectedChannel = defaults.first
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case connectTapped
        case retryTapped
        case disconnectTapped
        case connectionStateChanged(State.ConnectionState)
        case fudOfferTapped(String, meshOn: Bool)
        case dismissFudNotice
        case embeddedNodeStatusChanged(State.EmbeddedNodeStatus)
        case channelSelected(State.Channel)
        case sendMessage
        case messageReceived(State.Message)
        case removeOptimisticMessage(id: String, channel: String)
        case removeOptimisticDm(id: String, contactId: String)
        case bootstrapMessagesReceived([State.Message])
        case ircBridgeError(String)
        case dagSyncStatusUpdate(String?)
        case scenePhaseChanged(ScenePhase)
        // DM actions
        case tabSelected(State.ChatTab)
        case newDmTapped
        case newDmConversation(PresentationAction<NewDmConversation.Action>)
        case dmContactSelected(DmContact)
        case dmContactsLoaded([DmContact], [DmConversation])
        case dmBackTapped
        case sharePubkeyTapped
        case sharePubkeyConfirmed
        case sharePubkeyCancelled
        case dmKeypairMinted(secret: String, publicKey: String)
        case pubkeyGenerated(String)
        case dmMessageReceived(String, State.Message)  // contactId, message
        case settingsTapped
        case requestMoneyTapped
        case payInvoiceTapped(address: String, amount: String?, memo: String?)
        case walletRequest(amount: String, memo: String)
        case walletSend(address: String, amount: String, memo: String, tip: Bool)
        case postBroadcastedReceipt(ChatReceipt, channel: String?)
        case openNotifiedThread(String)
        case retryOutgoing(channel: String, text: String)
        case markOutgoingSent(id: String, channel: String)
        case markOutgoingFailed(id: String, channel: String)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case openChatSettings
            case requestMoney
            case payInvoice(address: String, amount: String?, memo: String?)
        }
    }

    private enum CancelID { case readLoop, connection }

    @Dependency(\.userStoredPreferences) var userStoredPreferences

    /// A relay to adapt UniFFI callbacks into an AsyncStream.
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

        func onMessage(eventId: String, channel: String, nick: String, message: String, timestamp: UInt64, isOutgoing: Bool) {
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

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.privacyNetwork = SessionPrivacyOverride.resolved(
                    stored: userStoredPreferences.walletPrivacyNetwork()
                )
                restoreChatHistoryIfEmpty(&state)
                if state.connectionState == .disconnected {
                    return .send(.connectTapped)
                }
                return .none

            case let .scenePhaseChanged(phase):
                switch phase {
                case .inactive, .background:
                    // Do NOT tear down the daemon on every background transition.
                    // The darkirc P2P connection survives short suspensions and
                    // the live relay_task keeps delivering events.  Only stop on
                    // sustained background (handled by the OS killing us).
                    return .none
                case .active:
                    // Check the actual native daemon status, not just UI state.
                    // The daemon may have died while backgrounded but the UI
                    // still shows "connected" because no state update fired.
                    let ffiStatus = darkircStatus()
                    let daemonDead = (ffiStatus == "not_running" || ffiStatus == "failed")
                    let uiDisconnected = (state.connectionState == .disconnected || state.connectionState == .error)

                    if daemonDead || uiDisconnected {
                        restoreChatHistoryIfEmpty(&state)
                        if !uiDisconnected {
                            // Daemon died silently — force UI to disconnected first
                            state.connectionState = .disconnected
                        }
                        return .send(.connectTapped)
                    }
                    return .none
                @unknown default:
                    return .none
                }

            case .connectTapped, .retryTapped:
                state.connectionState = .startingDaemon
                state.diagnosticDetail = nil
                state.dagSyncCount = 0
                restoreChatHistoryIfEmpty(&state)
                state.privacyNetwork = SessionPrivacyOverride.resolved(
                    stored: userStoredPreferences.walletPrivacyNetwork()
                )
                let nickname = state.nickname
                let network = state.privacyNetwork
                let torPort = UInt16(userStoredPreferences.torSocksPort() ?? "") ?? 9050
                let useEmbeddedTor = userStoredPreferences.useEmbeddedTor()
                let dagsCount = UInt32(max(1, userStoredPreferences.darkircDagsCount()))
                let fastMode = userStoredPreferences.darkircFastMode()

                return .run { send in
                    // The embedded darkirc daemon relays public-channel and DM
                    // events through the UniFFI `DarkircEventCallback.on_message`
                    // bridge (NOT a local IRC socket). We hand the daemon a
                    // callback that funnels messages into an AsyncStream the
                    // reducer consumes.
                    let daemon = DarkircDaemonManager.shared

                    await send(.embeddedNodeStatusChanged(.starting))
                    await send(.dagSyncStatusUpdate("Starting darkirc node…"))

                    let (stream, relay) = ChatEventRelay.makeStream(myNickname: nickname)

                    if network == .nym {
                        await send(.dagSyncStatusUpdate("Waiting for the Nym mixnet…"))
                        let ready = await waitForNymTunnel()
                        if !ready {
                            relay.finish()
                            await send(.ircBridgeError("Nym mixnet is not up"))
                            await send(.connectionStateChanged(.error))
                            await send(.embeddedNodeStatusChanged(.failed))
                            return
                        }
                    } else if network == .tor, useEmbeddedTor {
                        await send(.dagSyncStatusUpdate("Waiting for Tor (Arti)…"))
                        let ready = await waitForArtiTunnel(port: torPort)
                        if !ready {
                            relay.finish()
                            await send(.ircBridgeError("Tor (Arti) is not up"))
                            await send(.connectionStateChanged(.error))
                            await send(.embeddedNodeStatusChanged(.failed))
                            return
                        }
                    }

                    let transport: DarkircTransport = switch network {
                    case .nym: .nym
                    case .tor: .tor
                    case .direct: .direct
                    }
                    let socksPort: UInt16 = network == .tor ? torPort : NighthawkSetting.PrivacyNetwork.nymSocksPort

                    do {
                        configureDarkirc(dagsCount: dagsCount, fastMode: fastMode)
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

                    // Wait until the Rust daemon reports STATUS_RUNNING and CONNECTION_PHASE == "connected"
                    // (DAG_SYNCED == 1) before marking Chat connected or flushing ChatOutboxStore.
                    var pollCount = 0
                    let maxPolls = 90
                    var reachedConnected = false
                    while pollCount < maxPolls {
                        guard !Task.isCancelled else {
                            relay.finish()
                            return
                        }
                        do {
                            try await Task.sleep(for: .seconds(1))
                        } catch {
                            relay.finish()
                            return
                        }
                        guard !Task.isCancelled else {
                            relay.finish()
                            return
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
                            return
                        case "running":
                            if ffiPhase == "connected" {
                                reachedConnected = true
                                await send(.embeddedNodeStatusChanged(.ready))
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

                        if reachedConnected {
                            break
                        }
                    }

                    guard reachedConnected else {
                        relay.finish()
                        let diag = "darkirc did not finish DAG sync (status: \(darkircStatus()), phase: \(darkircConnectionPhase()))"
                        await send(.ircBridgeError(diag))
                        await send(.connectionStateChanged(.error))
                        await send(.embeddedNodeStatusChanged(.failed))
                        return
                    }

                    await send(.embeddedNodeStatusChanged(.ready))
                    let connected: State.ConnectionState = switch network {
                    case .nym: .connectedViaNym
                    case .tor: .connectedViaTor
                    case .direct: .connectedDirect
                    }
                    await send(.connectionStateChanged(connected))
                    await send(.dagSyncStatusUpdate(nil))

                    // Consume incoming messages from the Rust daemon callback
                    // bridge. The daemon also replays historical DAG events
                    // through this same callback after sync completes.
                    for await msg in stream {
                        await send(.messageReceived(msg))
                    }

                    await send(.connectionStateChanged(.disconnected))
                    await send(.embeddedNodeStatusChanged(.notUsed))
                }
                .cancellable(id: CancelID.connection, cancelInFlight: true)

            case .disconnectTapped:
                DarkircDaemonManager.shared.stop()
                state.connectionState = .disconnected
                state.embeddedNodeStatus = .notUsed
                state.diagnosticDetail = nil
                return .cancel(id: CancelID.connection)

            case .dismissFudNotice:
                state.fudNotice = nil
                return .none
            case let .fudOfferTapped(raw, meshOn):
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
            case let .connectionStateChanged(newState):
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
                    // Keep a specific ircBridgeError that was just recorded.
                    // Only fill the generic hint when nothing more precise exists.
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
                if newState.isConnected {
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
                return .none

            case let .embeddedNodeStatusChanged(status):
                state.embeddedNodeStatus = status
                return .none

            case let .channelSelected(channel):
                let previous = state.composerKey
                state.selectedChannel = channel
                state.messages = IdentifiedArrayOf(
                    uniqueElements: state.channelMessages[channel.name] ?? []
                )
                state.moveComposer(from: previous)
                // Clear unread
                if let idx = state.channels.index(id: channel.id) {
                    state.channels[idx].unreadCount = 0
                }
                return .none

            case .sendMessage:
                let text = state.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return .none }
                // Direct tab always uses the open DM. Never fall through to #dev.
                if state.selectedTab == .direct {
                    return sendDirectMessage(state: &state, text: text)
                }
                guard let channel = state.selectedChannel else { return .none }

                state.composerDrafts.removeValue(forKey: state.composerKey)
                state.composedMessage = ""

                // Handle all DarkIRC slash commands as per DarkFi manual
                if text.hasPrefix("/") {
                    let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                    let cmd = parts.first?.lowercased() ?? ""
                    let arg = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

                    switch cmd {
                    case "/nick":
                        if !arg.isEmpty && arg.count <= DarkfiChatDefaults.maxNickLen {
                            let sanitized = DarkfiChatDefaults.sanitizeNickname(arg)
                            state.nickname = sanitized
                            DarkfiChatDefaults.setNickname(sanitized)
                            let sysMsg = State.Message(
                                id: UUID().uuidString,
                                sender: "System",
                                content: "Your nickname is now: \(sanitized)",
                                channel: channel.name,
                                timestamp: Date(),
                                isOutgoing: false
                            )
                            state.messages.append(sysMsg)
                            state.channelMessages[channel.name, default: []].append(sysMsg)
                            return .none
                        }
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Invalid nickname. Usage: /nick <name> (1–24 alphanumeric/underscore characters)",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    case "/join":
                        if !arg.isEmpty {
                            let previous = state.composerKey
                            let targetChan = arg.hasPrefix("#") ? arg : "#\(arg)"
                            if state.channels[id: targetChan] == nil {
                                let newChan = State.Channel(name: targetChan)
                                state.channels.append(newChan)
                            }
                            if let channel = state.channels[id: targetChan] {
                                state.selectedChannel = channel
                                state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[channel.name] ?? [])
                            }
                            state.moveComposer(from: previous)
                            let sysMsg = State.Message(
                                id: UUID().uuidString,
                                sender: "System",
                                content: "Joined channel: \(targetChan)",
                                channel: targetChan,
                                timestamp: Date(),
                                isOutgoing: false
                            )
                            state.messages.append(sysMsg)
                            state.channelMessages[targetChan, default: []].append(sysMsg)
                            return .none
                        }
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Usage: /join <#channel>",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    case "/part", "/leave":
                        let previous = state.composerKey
                        let targetChan = channel.name
                        state.channels.remove(id: targetChan)
                        state.channelMessages.removeValue(forKey: targetChan)
                        state.composerDrafts.removeValue(forKey: "ch:\(channel.id)")
                        if let first = state.channels.first {
                            state.selectedChannel = first
                            state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[first.name] ?? [])
                        } else {
                            state.selectedChannel = nil
                            state.messages = []
                        }
                        state.moveComposer(from: previous)
                        return .none

                    case "/clear":
                        state.channelMessages[channel.name] = []
                        state.messages = []
                        return .none

                    case "/me":
                        if !arg.isEmpty {
                            let actionText = "* \(state.nickname) \(arg)"
                            let message = State.Message(
                                sender: state.nickname,
                                content: actionText,
                                channel: channel.name,
                                isOutgoing: true
                            )
                            state.messages.append(message)
                            state.channelMessages[channel.name, default: []].append(message)
                            state.seenEventIds.insert(message.id)

                            let channelTarget = channel.name
                            let nick = state.nickname
                            let optimisticId = message.id
                            return .run { send in
                                do {
                                    try sendChatMessage(channel: channelTarget, nick: nick, message: actionText)
                                } catch {
                                    await send(.ircBridgeError("Send failed: \(error.localizedDescription)"))
                                    await send(.removeOptimisticMessage(id: optimisticId, channel: channelTarget))
                                }
                            }
                        }
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Usage: /me <action>",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    case "/msg":
                        let msgParts = arg.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                        if msgParts.count == 2 {
                            let target = String(msgParts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                            let msgContent = String(msgParts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                            let nick = state.nickname
                            return .run { send in
                                do {
                                    try sendChatMessage(channel: target, nick: nick, message: msgContent)
                                } catch {
                                    await send(.ircBridgeError("Send /msg failed: \(error.localizedDescription)"))
                                }
                            }
                        }
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Usage: /msg <target> <message>",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    case "/help":
                        let helpText = [
                            "Available DarkIRC commands:",
                            "  /nick <name> — Change nickname (1–24 characters)",
                            "  /join <#channel> — Join or switch to channel",
                            "  /part — Leave current channel",
                            "  /clear — Clear messages in current view",
                            "  /me <action> — Send action message (* nick action)",
                            "  /msg <target> <text> — Send message to channel or nick",
                            "  /help — Show this help message"
                        ].joined(separator: "\n")
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: helpText,
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    default:
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Unknown command '\(cmd)'. Type /help for DarkIRC commands.",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none
                    }
                }

                // Optimistic local insert for both public channels and DMs.
                // Public sends previously waited only on EventGraph self-echo,
                // which often never reached the UI while status already showed
                // Connected — making "hi" vanish from #dev.
                let offline = !state.connectionState.isConnected
                let message = State.Message(
                    id: offline ? "queued-\(UUID().uuidString)" : "local-\(UUID().uuidString)",
                    sender: state.nickname,
                    content: text,
                    channel: channel.name,
                    isOutgoing: true
                )
                state.messages.append(message)
                state.channelMessages[channel.name, default: []].append(message)
                state.seenEventIds.insert(message.id)
                ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)

                let channelTarget = channel.name
                let nick = state.nickname
                let optimisticId = message.id
                if offline {
                    return .run { send in
                        _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: channelTarget, text: text)
                        await send(.ircBridgeError("Queued offline — will send when DarkIRC reconnects"))
                    }
                }
                return .run { send in
                    do {
                        try sendChatMessage(channel: channelTarget, nick: nick, message: text)
                    } catch {
                        _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: channelTarget, text: text)
                        await send(.ircBridgeError("Send failed; queued for retry: \(error.localizedDescription)"))
                        await send(.markOutgoingFailed(id: optimisticId, channel: channelTarget))
                    }
                }

            case let .messageReceived(message):
                // Deduplicate: skip if this event was already delivered
                guard !state.seenEventIds.contains(message.id) else {
                    return .none
                }
                state.seenEventIds.insert(message.id)

                // Non-# targets are E2E DMs. Decrypt with the contact store and
                // deliver through dmMessageReceived — do not file them on #dev.
                if !message.channel.hasPrefix("#") {
                    let eventId = message.id
                    let sender = message.sender
                    let content = message.content
                    let channel = message.channel
                    let timestamp = message.timestamp
                    let isOutgoing = message.isOutgoing
                    let viewingContactId = state.selectedTab == .direct ? state.selectedDmContact?.id : nil
                    return .run { send in
                        await deliverDirectMessage(
                            send: send,
                            eventId: eventId,
                            sender: sender,
                            content: content,
                            channel: channel,
                            timestamp: timestamp,
                            isOutgoing: isOutgoing,
                            viewingContactId: viewingContactId
                        )
                    }
                }

                // Prune to cap memory: seenEventIds grows with every received
                // event. Once we exceed 10k we drop the set — all live messages
                // are already in channelMessages so dups are unlikely at this
                // point.
                if state.seenEventIds.count > 10_000 {
                    state.seenEventIds = []
                }

                // Replace optimistic local bubbles (UUID ids) with the real
                // EventGraph echo (same sender + content on the same channel).
                let isOptimisticLocal: (State.Message) -> Bool = { local in
                    local.isOutgoing &&
                        local.sender == message.sender &&
                        local.content == message.content &&
                        local.id != message.id &&
                        isChatDeliveryId(local.id)
                }

                var bucket = state.channelMessages[message.channel] ?? []
                let removedIds = Set(bucket.filter(isOptimisticLocal).map(\.id))
                bucket.removeAll(where: isOptimisticLocal)
                bucket.append(message)
                state.channelMessages[message.channel] = bucket
                for removed in removedIds {
                    state.seenEventIds.remove(removed)
                }

                if state.selectedChannel?.name == message.channel {
                    state.messages.removeAll(where: isOptimisticLocal)
                    state.messages.append(message)
                } else if let idx = state.channels.firstIndex(where: { $0.name == message.channel }) {
                    state.channels[idx].unreadCount += 1
                }

                state.dagSyncCount += 1
                ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
                ChatNotificationRouter.maybeNotify(
                    nick: message.sender,
                    body: message.content,
                    thread: message.channel,
                    isOutgoing: message.isOutgoing,
                    timestamp: message.timestamp,
                    ownNick: state.nickname
                )
                return .none

            case let .removeOptimisticMessage(id, channel):
                state.seenEventIds.remove(id)
                state.channelMessages[channel]?.removeAll { $0.id == id }
                if state.selectedChannel?.name == channel {
                    state.messages.removeAll { $0.id == id }
                }
                return .none

            case let .removeOptimisticDm(id, contactId):
                state.seenEventIds.remove(id)
                state.dmMessages[contactId]?.removeAll { $0.id == id }
                if state.selectedDmContact?.id == contactId {
                    state.messages.removeAll { $0.id == id }
                }
                return .none

            case let .dagSyncStatusUpdate(progress):
                state.dagSyncProgress = progress
                return .none

            case let .bootstrapMessagesReceived(messages):
                state.dagSyncCount = messages.count
                for msg in messages {
                    state.channelMessages[msg.channel, default: []].append(msg)
                }

                // Load messages for selected channel
                if let selected = state.selectedChannel {
                    state.messages = IdentifiedArrayOf(
                        uniqueElements: state.channelMessages[selected.name] ?? []
                    )
                }
                ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
                return .none

            case let .ircBridgeError(detail):
                state.diagnosticDetail = detail
                return .none

            // MARK: - DM actions

            case let .tabSelected(tab):
                let previous = state.composerKey
                state.selectedTab = tab
                state.moveComposer(from: previous)
                if tab == .direct {
                    // Load DM contacts from store
                    return .run { send in
                        let contacts = await DarkircCryptoStore.shared.allContacts()
                        let convos = await DarkircCryptoStore.shared.allConversations()
                        await send(.dmContactsLoaded(contacts, convos))
                    }
                }
                return .none

            case .newDmTapped:
                var dmState = NewDmConversation.State()
                dmState.myPublicKey = userStoredPreferences.dmPublicKey() ?? ""
                dmState.mySecretKey = userStoredPreferences.dmSecretKey() ?? ""
                state.newDmConversation = dmState
                return .none

            case .settingsTapped:
                return .send(.delegate(.openChatSettings))

            case .requestMoneyTapped:
                return .send(.delegate(.requestMoney))

            case let .payInvoiceTapped(address, amount, memo):
                return .send(.delegate(.payInvoice(address: address, amount: amount, memo: memo)))

            case let .walletRequest(amount, memo):
                let address = state.receiveAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !address.isEmpty else {
                    state.diagnosticDetail = "Wallet address is not ready yet."
                    return .none
                }
                let amountText = amount.trimmingCharacters(in: .whitespacesAndNewlines)
                let memoText = memo.trimmingCharacters(in: .whitespacesAndNewlines)
                state.composedMessage = PaymentRequestUri.build(
                    address: address,
                    amount: amountText.isEmpty ? nil : amountText,
                    memo: memoText.isEmpty ? nil : memoText
                )
                return .send(.sendMessage)

            case let .walletSend(address, amount, memo, tip):
                let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedAddress.isEmpty else {
                    state.diagnosticDetail = "Enter a wallet address to pay."
                    return .none
                }
                let amountText = amount.trimmingCharacters(in: .whitespacesAndNewlines)
                let typedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
                let memoText: String? = typedMemo.isEmpty ? (tip ? "Tip" : nil) : typedMemo
                let targetChannel: String? = state.selectedTab == .direct
                    ? state.selectedDmContact?.contactLabel
                    : state.selectedChannel?.name
                let receipt = ChatReceipt(
                    id: UUID().uuidString,
                    phase: .pending,
                    amount: amountText.isEmpty ? "0" : amountText,
                    address: trimmedAddress,
                    memo: memoText
                )
                ChatReceiptBook.stage(receipt, targetChannel: targetChannel)
                return .send(.delegate(.payInvoice(
                    address: trimmedAddress,
                    amount: amountText.isEmpty ? nil : amountText,
                    memo: memoText
                )))

            case let .postBroadcastedReceipt(receipt, channel):
                let encoded = ChatReceiptCodec.encode(receipt)
                let target = channel?.trimmingCharacters(in: .whitespacesAndNewlines)
                if let target, !target.isEmpty, !target.hasPrefix("#"),
                   let contact = state.dmContacts.first(where: {
                       $0.contactLabel.caseInsensitiveCompare(target) == .orderedSame
                   }) {
                    return sendDirectMessage(state: &state, text: encoded, targetContact: contact)
                }
                let targetChannel = (target?.isEmpty == false ? target : nil) ?? state.selectedChannel?.name
                guard let channelName = targetChannel, !channelName.isEmpty else { return .none }
                let offline = !state.connectionState.isConnected
                let message = State.Message(
                    id: offline ? "queued-\(UUID().uuidString)" : "local-\(UUID().uuidString)",
                    sender: state.nickname,
                    content: encoded,
                    channel: channelName,
                    isOutgoing: true
                )
                state.channelMessages[channelName, default: []].append(message)
                if state.selectedTab == .channels && state.selectedChannel?.name == channelName {
                    state.messages.append(message)
                }
                state.seenEventIds.insert(message.id)
                ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
                let nick = state.nickname
                let optimisticId = message.id
                if offline {
                    return .run { _ in
                        _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: channelName, text: encoded)
                    }
                }
                return .run { send in
                    do {
                        try sendChatMessage(channel: channelName, nick: nick, message: encoded)
                    } catch {
                        _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: channelName, text: encoded)
                        await send(.markOutgoingFailed(id: optimisticId, channel: channelName))
                    }
                }

            case let .openNotifiedThread(thread):
                let key = thread.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty else { return .none }
                if key.hasPrefix("#") {
                    let channel = state.channels.first {
                        $0.name.caseInsensitiveCompare(key) == .orderedSame
                    } ?? State.Channel(name: key)
                    if state.channels[id: channel.id] == nil {
                        state.channels.append(channel)
                    }
                    return .merge(
                        .send(.tabSelected(.channels)),
                        .send(.channelSelected(channel))
                    )
                }
                if let contact = state.dmContacts.first(where: {
                    $0.contactLabel.caseInsensitiveCompare(key) == .orderedSame || $0.id == key
                }) {
                    return .merge(
                        .send(.tabSelected(.direct)),
                        .send(.dmContactSelected(contact))
                    )
                }
                return .send(.tabSelected(.direct))

            case let .retryOutgoing(channel, text):
                let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !body.isEmpty else { return .none }
                var removedIds: [String] = []
                if var bucket = state.channelMessages[channel] {
                    for msg in bucket where msg.id.hasPrefix("failed-") && msg.content == body {
                        removedIds.append(msg.id)
                    }
                    bucket.removeAll { msg in removedIds.contains(msg.id) }
                    state.channelMessages[channel] = bucket
                }
                if let contact = state.dmContacts.first(where: {
                    $0.contactLabel.caseInsensitiveCompare(channel) == .orderedSame
                }), var bucket = state.dmMessages[contact.id] {
                    for msg in bucket where msg.id.hasPrefix("failed-") && msg.content == body {
                        removedIds.append(msg.id)
                    }
                    bucket.removeAll { msg in removedIds.contains(msg.id) }
                    state.dmMessages[contact.id] = bucket
                }
                for rid in removedIds {
                    state.messages.remove(id: rid)
                    state.seenEventIds.remove(rid)
                }
                if !removedIds.isEmpty {
                    ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
                }
                let outboxIdsToClear = removedIds.map { id in
                    id.hasPrefix("failed-") ? String(id.dropFirst("failed-".count)) : id
                }
                state.composedMessage = body
                return .merge(
                    .run { _ in
                        for oid in outboxIdsToClear {
                            await ChatOutboxStore.shared.remove(id: oid)
                        }
                    },
                    .send(.sendMessage)
                )

            case let .markOutgoingSent(id, channel):
                let sentId = "local-\(UUID().uuidString)"
                return updateOutgoingDelivery(
                    state: &state,
                    oldId: id,
                    newId: sentId,
                    channel: channel
                )

            case let .markOutgoingFailed(id, channel):
                let failedId = id.hasPrefix("failed-") ? id : "failed-\(id)"
                return updateOutgoingDelivery(
                    state: &state,
                    oldId: id,
                    newId: failedId,
                    channel: channel
                )

            case .delegate:
                return .none

            case .newDmConversation(.presented(.dismiss)):
                state.newDmConversation = nil
                // Refresh contacts
                return .run { send in
                    let contacts = await DarkircCryptoStore.shared.allContacts()
                    let convos = await DarkircCryptoStore.shared.allConversations()
                    await send(.dmContactsLoaded(contacts, convos))
                }

            case let .newDmConversation(.presented(.contactSaved(contact))):
                if (userStoredPreferences.dmSecretKey() ?? "").isEmpty,
                   !contact.mySecretB58.isEmpty {
                    userStoredPreferences.setDmSecretKey(contact.mySecretB58)
                    userStoredPreferences.setDmPublicKey(contact.myPublicB58)
                }
                return .none

            case .newDmConversation:
                return .none

            case .dmBackTapped:
                let previous = state.composerKey
                state.selectedDmContact = nil
                state.messages = []
                state.moveComposer(from: previous)
                return .none

            case let .dmContactSelected(contact):
                let previous = state.composerKey
                state.selectedDmContact = contact
                state.moveComposer(from: previous)
                state.messages = IdentifiedArrayOf(
                    uniqueElements: state.dmMessages[contact.id] ?? []
                )
                // Clear unread
                return .run { _ in
                    await DarkircCryptoStore.shared.clearUnread(contactId: contact.id)
                }

            case let .dmContactsLoaded(contacts, convos):
                state.dmContacts = contacts
                state.dmConversations = convos
                return .none

            case .sharePubkeyTapped:
                state.showSharePubkeyWarning = true
                return .none

            case .sharePubkeyConfirmed:
                state.showSharePubkeyWarning = false
                if let existing = userStoredPreferences.dmPublicKey()?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !existing.isEmpty {
                    return .send(.pubkeyGenerated(existing))
                }
                return .run { send in
                    if let keypair = DarkircContactManager.generateKeypair() {
                        await send(.dmKeypairMinted(secret: keypair.secretB58, publicKey: keypair.publicB58))
                    }
                }

            case let .dmKeypairMinted(secret, publicKey):
                guard !publicKey.isEmpty else { return .none }
                userStoredPreferences.setDmSecretKey(secret)
                userStoredPreferences.setDmPublicKey(publicKey)
                return .send(.pubkeyGenerated(publicKey))

            case .sharePubkeyCancelled:
                state.showSharePubkeyWarning = false
                return .none

            case let .pubkeyGenerated(publicKey):
                state.myDmPublicKey = publicKey
                // Copy to clipboard with 60-second auto-expiry
                let shareText = DarkircDmPubkeyParser.formatForSharing(publicKey)
                UIPasteboard.general.setItems(
                    [[UIPasteboard.typeAutomatic: shareText]],
                    options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(60)]
                )
                return .none

            case let .dmMessageReceived(contactId, message):
                if state.dmMessages[contactId]?.contains(where: { $0.id == message.id }) == true {
                    return .none
                }
                let isOptimisticLocal: (State.Message) -> Bool = { local in
                    local.isOutgoing &&
                        local.sender == message.sender &&
                        local.content == message.content &&
                        local.id != message.id &&
                        isChatDeliveryId(local.id)
                }
                state.dmMessages[contactId, default: []].removeAll(where: isOptimisticLocal)
                state.dmMessages[contactId, default: []].append(message)
                let viewing = state.selectedTab == .direct && state.selectedDmContact?.id == contactId
                if viewing {
                    state.messages.removeAll(where: isOptimisticLocal)
                    state.messages.append(message)
                }
                if let idx = state.dmConversations.firstIndex(where: { $0.id == contactId }) {
                    state.dmConversations[idx].lastMessageText = message.content
                    state.dmConversations[idx].lastMessageAt = message.timestamp
                    if !viewing && !message.isOutgoing {
                        state.dmConversations[idx].unreadCount += 1
                    }
                }
                ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
                ChatNotificationRouter.maybeNotify(
                    nick: message.sender,
                    body: message.content,
                    thread: message.channel.isEmpty ? contactId : message.channel,
                    isOutgoing: message.isOutgoing,
                    timestamp: message.timestamp,
                    ownNick: state.nickname
                )
                return .none
            }
        }
        .ifLet(\.$newDmConversation, action: \.newDmConversation) {
            NewDmConversation()
        }
    }

    public init() {}
}

private func restoreChatHistoryIfEmpty(_ state: inout Chat.State) {
    guard state.channelMessages.isEmpty && state.dmMessages.isEmpty else { return }
    let loaded = ChatHistoryStore.load()
    state.channelMessages = loaded.channels
    state.dmMessages = loaded.dms
    state.seenEventIds.formUnion(loaded.ids)
    if state.selectedTab == .channels, let name = state.selectedChannel?.name {
        state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[name] ?? [])
    }
}

private func isChatDeliveryId(_ id: String) -> Bool {
    if UUID(uuidString: id) != nil { return true }
    return id.hasPrefix("queued-") || id.hasPrefix("local-") || id.hasPrefix("failed-")
}

private func updateOutgoingDelivery(
    state: inout Chat.State,
    oldId: String,
    newId: String,
    channel: String
) -> Effect<Chat.Action> {
    var didChange = false
    if var bucket = state.channelMessages[channel],
       let idx = bucket.firstIndex(where: { $0.id == oldId }) {
        let old = bucket[idx]
        let updated = Chat.State.Message(
            id: newId,
            sender: old.sender,
            content: old.content,
            channel: old.channel,
            timestamp: old.timestamp,
            isOutgoing: true,
            failedToDecrypt: old.failedToDecrypt
        )
        bucket[idx] = updated
        state.channelMessages[channel] = bucket
        didChange = true
        if state.selectedTab == .channels && state.selectedChannel?.name == channel,
           let msgIdx = state.messages.index(id: oldId) {
            state.messages[msgIdx] = updated
        }
    }
    if let contact = state.dmContacts.first(where: {
        $0.contactLabel.caseInsensitiveCompare(channel) == .orderedSame
    }), var bucket = state.dmMessages[contact.id],
       let idx = bucket.firstIndex(where: { $0.id == oldId }) {
        let old = bucket[idx]
        let updated = Chat.State.Message(
            id: newId,
            sender: old.sender,
            content: old.content,
            channel: old.channel,
            timestamp: old.timestamp,
            isOutgoing: true,
            failedToDecrypt: old.failedToDecrypt
        )
        bucket[idx] = updated
        state.dmMessages[contact.id] = bucket
        didChange = true
        if state.selectedTab == .direct && state.selectedDmContact?.id == contact.id,
           let msgIdx = state.messages.index(id: oldId) {
            state.messages[msgIdx] = updated
        }
    }
    guard didChange else { return .none }
    state.seenEventIds.remove(oldId)
    state.seenEventIds.insert(newId)
    ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
    return .none
}

/// Register the contact's ChaCha keys with Rust and PRIVMSG the contact label.
/// Rust handles ChaChaBox encryption on the wire; public `selectedChannel` (#dev) is not a fallback.
private func sendDirectMessage(
    state: inout Chat.State,
    text: String,
    targetContact: DmContact? = nil
) -> Effect<Chat.Action> {
    guard let contact = targetContact ?? state.selectedDmContact else { return .none }
    if targetContact == nil {
        state.composerDrafts.removeValue(forKey: state.composerKey)
        state.composedMessage = ""
    }

    if targetContact == nil && text.hasPrefix("/") {
        return handleDirectSlash(state: &state, contact: contact, text: text)
    }

    let offline = !state.connectionState.isConnected
    let message = Chat.State.Message(
        id: offline ? "queued-\(UUID().uuidString)" : "local-\(UUID().uuidString)",
        sender: state.nickname,
        content: text,
        channel: contact.contactLabel,
        isOutgoing: true
    )
    state.dmMessages[contact.id, default: []].append(message)
    if state.selectedTab == .direct && state.selectedDmContact?.id == contact.id {
        state.messages.append(message)
    }
    state.seenEventIds.insert(message.id)
    ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)

    let secret = contact.mySecretB58
    let theirPublic = contact.theirPublicB58
    let label = contact.contactLabel
    let nick = state.nickname
    let contactId = contact.id
    let optimisticId = message.id
    if offline {
        return .run { _ in
            _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: label, text: text)
        }
    }

    return .run { send in
        guard let skBytes = Base58.decode(secret), skBytes.count == 32,
              let pkBytes = Base58.decode(theirPublic), pkBytes.count == 32 else {
            await send(.ircBridgeError("Invalid DM keys for \(label)"))
            await send(.removeOptimisticDm(id: optimisticId, contactId: contactId))
            return
        }
        do {
            try registerDmContact(nick: label, mySecret: skBytes, theirPublic: pkBytes)
        } catch {
            await send(.ircBridgeError("DM contact was not registered"))
            await send(.removeOptimisticDm(id: optimisticId, contactId: contactId))
            return
        }
        do {
            try sendChatMessage(channel: label, nick: nick, message: text)
            await DarkircCryptoStore.shared.updateConversation(
                contactId: contactId,
                lastMessage: text,
                incrementUnread: false
            )
        } catch {
            _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: label, text: text)
            await send(.ircBridgeError("Send failed; queued for retry: \(error.localizedDescription)"))
            await send(.markOutgoingFailed(id: optimisticId, channel: label))
        }
    }
}

private func handleDirectSlash(
    state: inout Chat.State,
    contact: DmContact,
    text: String
) -> Effect<Chat.Action> {
    let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
    let cmd = parts.first?.lowercased() ?? ""
    let arg = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

    func local(_ content: String) {
        let sys = Chat.State.Message(
            sender: "System",
            content: content,
            channel: contact.contactLabel,
            isOutgoing: false
        )
        state.dmMessages[contact.id, default: []].append(sys)
        state.messages.append(sys)
    }

    switch cmd {
    case "/clear":
        state.dmMessages[contact.id] = []
        state.messages = []
        return .none
    case "/help":
        local("DM commands: /me <action>, /clear, /help. Messages are encrypted to \(contact.contactLabel).")
        return .none
    case "/me":
        guard !arg.isEmpty else {
            local("Usage: /me <action>")
            return .none
        }
        return sendDirectMessage(state: &state, text: "* \(state.nickname) \(arg)")
    default:
        local("Command \(cmd) stays on public channels. This DM is encrypted to \(contact.contactLabel).")
        return .none
    }
}

private func deliverDirectMessage(
    send: Send<Chat.Action>,
    eventId: String,
    sender: String,
    content: String,
    channel: String,
    timestamp: Date,
    isOutgoing: Bool,
    viewingContactId: String?
) async {
    let contacts = await DarkircCryptoStore.shared.allContacts()
    let labeled = contacts.first {
        $0.contactLabel.compare(channel, options: .caseInsensitive) == .orderedSame
    }
    if let labeled {
        let plain = DarkircContactManager.decryptMessage(
            mySecretB58: labeled.mySecretB58,
            theirPublicB58: labeled.theirPublicB58,
            ciphertextB58: content
        )
        let decoded = Chat.State.Message(
            id: eventId,
            sender: sender,
            content: plain ?? content,
            channel: labeled.contactLabel,
            timestamp: timestamp,
            isOutgoing: isOutgoing,
            failedToDecrypt: false
        )
        let unread = !isOutgoing && viewingContactId != labeled.id
        await DarkircCryptoStore.shared.updateConversation(
            contactId: labeled.id,
            lastMessage: decoded.content,
            at: timestamp,
            incrementUnread: unread
        )
        await send(.dmMessageReceived(labeled.id, decoded))
        return
    }
    if let any = DarkircContactManager.tryDecryptWithAnyContact(
        ciphertextB58: content,
        contacts: contacts
    ) {
        let decoded = Chat.State.Message(
            id: eventId,
            sender: sender,
            content: any.plaintext,
            channel: any.contact.contactLabel,
            timestamp: timestamp,
            isOutgoing: isOutgoing
        )
        let unread = !isOutgoing && viewingContactId != any.contact.id
        await DarkircCryptoStore.shared.updateConversation(
            contactId: any.contact.id,
            lastMessage: any.plaintext,
            at: timestamp,
            incrementUnread: unread
        )
        await send(.dmMessageReceived(any.contact.id, decoded))
    }
}

/// Poll until the in-process Nym tunnel reports ready, or the native bootstrap fails.
private func waitForNymTunnel() async -> Bool {
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
private func waitForArtiTunnel(port: UInt16) async -> Bool {
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
// swiftlint:enable type_body_length
