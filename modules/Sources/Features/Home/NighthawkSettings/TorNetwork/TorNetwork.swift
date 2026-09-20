//
//  TorNetwork.swift
//  stealth
//
//  Tor network settings reducer — matches Android's AppTorCoordinator + TorNetworkSettingsScreen.
//  Manages in-process Arti SOCKS proxy for wallet RPC and DarkIRC chat P2P routing.
//

import ComposableArchitecture
import DarkfiCore
import Foundation
import MnemonicClient
import SDKSynchronizer
import UserPreferencesStorage
import WalletStorage

@Reducer
public struct TorNetwork {
    @ObservableState
    public struct State: Equatable {
        // ── Routing toggle (single app-wide toggle matching Android) ────
        public var torForWallet: Bool = true
        public var torForChat: Bool = true

        // ── Tor provider ────────────────────────────────────────────────
        public enum TorMode: String, Equatable, CaseIterable {
            case embeddedArti  // In-process Rust Arti SOCKS
            case externalSocks // External Tor/SOCKS5 proxy
        }
        public var torMode: TorMode = .embeddedArti

        // ── External SOCKS (used when torMode == .externalSocks) ───────
        public var externalSocksAddress: String = "127.0.0.1"
        public var externalSocksPort: String = "9050"

        // ── Arti status ────────────────────────────────────────────────
        public enum ArtiStatus: String, Equatable {
            case stopped = "Stopped"
            case bootstrapping = "Bootstrapping…"
            case connected = "Connected"
            case failed = "Failed"
        }
        public var artiStatus: ArtiStatus = .stopped
        public var artiBootstrapProgress: Double = 0.0
        public var walletRestartError: String?

        // ── Derived ────────────────────────────────────────────────────
        public var isTorEnabled: Bool { torForWallet || torForChat }
        public var isUsingEmbedded: Bool { torMode == .embeddedArti }

        public var socksEndpoint: String {
            if isUsingEmbedded {
                return "127.0.0.1:9050"
            }
            return "\(externalSocksAddress):\(externalSocksPort)"
        }

        /// Descriptive text for the SOCKS section matching Android's two descriptions.
        public var socksDescription: String {
            if isUsingEmbedded && isTorEnabled {
                return "Loopback address where built-in Arti listens (default 127.0.0.1:9050). Embedded DarkIRC uses this proxy for .onion P2P seeds."
            }
            return "Host and port of your external Tor or SOCKS proxy. Required when built-in Arti is off."
        }

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear

        // Route toggles
        case torForWalletToggled(Bool)
        case torForChatToggled(Bool)

        // Provider
        case torModeChanged(State.TorMode)

        // Arti lifecycle
        case startArti
        case stopArti
        case artiStatusChanged(State.ArtiStatus)
        case artiBootstrapProgressUpdated(Double)

        // Apply & restart
        case applyAndReconnect
        case applyCompleted
        case walletReopenFailed(String, revertTo: Bool?)
        case doneTapped

        // Delegate
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
        }
    }

    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.mnemonic) var mnemonic

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.torForWallet = userStoredPreferences.torForWalletEnabled()
                state.torForChat = userStoredPreferences.torForChatEnabled()
                state.torMode = userStoredPreferences.useEmbeddedTor()
                    ? .embeddedArti : .externalSocks
                if let host = userStoredPreferences.torSocksHost() {
                    state.externalSocksAddress = host
                }
                if let port = userStoredPreferences.torSocksPort() {
                    state.externalSocksPort = port
                }
                if DarkfiFfiSafe.isArtiRunning() {
                    state.artiStatus = .connected
                    state.artiBootstrapProgress = 1.0
                }
                return .none

            case let .torForWalletToggled(enabled):
                let previous = state.torForWallet
                state.torForWallet = enabled
                state.torForChat = enabled
                state.walletRestartError = nil
                userStoredPreferences.setTorForWalletEnabled(enabled)
                userStoredPreferences.setTorForChatEnabled(enabled)
                return .merge(
                    resolveArtiLifecycle(state: &state),
                    reopenWalletIfPresent(previousWalletTor: previous)
                )

            case let .torForChatToggled(enabled):
                state.torForChat = enabled
                userStoredPreferences.setTorForChatEnabled(enabled)
                return resolveArtiLifecycle(state: &state)

            case let .torModeChanged(mode):
                state.torMode = mode
                userStoredPreferences.setUseEmbeddedTor(mode == .embeddedArti)
                return resolveArtiLifecycle(state: &state)

            case .startArti:
                guard state.artiStatus != .bootstrapping,
                      state.artiStatus != .connected else { return .none }
                state.artiStatus = .bootstrapping
                state.artiBootstrapProgress = 0.0
                let portString = state.externalSocksPort
                return .run { send in
                    await send(.artiBootstrapProgressUpdated(0.1))
                    let port = UInt16(portString) ?? 9050
                    // `start_arti_proxy` may return false when already running;
                    // always wait for bootstrap readiness.
                    let ready = await TorBootstrap.ensureReady(socksPort: port)
                    await send(.artiBootstrapProgressUpdated(1.0))
                    await send(.artiStatusChanged(ready ? .connected : .failed))
                }

            case .stopArti:
                DarkfiFfiSafe.stopArtiProxy()
                state.artiStatus = .stopped
                state.artiBootstrapProgress = 0.0
                return .none

            case let .artiStatusChanged(status):
                state.artiStatus = status
                return .none

            case let .artiBootstrapProgressUpdated(progress):
                state.artiBootstrapProgress = progress
                return .none

            case .applyAndReconnect:
                userStoredPreferences.setTorSocksHost(state.externalSocksAddress)
                userStoredPreferences.setTorSocksPort(state.externalSocksPort)

                let torEnabled = state.isTorEnabled
                let useEmbedded = state.isUsingEmbedded
                let socksPort = state.externalSocksPort

                return .run { send in
                    if torEnabled && useEmbedded {
                        let port = UInt16(socksPort) ?? 9050
                        _ = DarkfiFfiSafe.startArtiProxySafely(socksPort: port)
                    } else if !torEnabled || !useEmbedded {
                        DarkfiFfiSafe.stopArtiProxy()
                    }

                    if (try? walletStorage.areKeysPresent()) == true {
                        do {
                            let storedWallet = try walletStorage.exportWallet()
                            let birthday = storedWallet.birthday?.value() ?? 0
                            let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                            sdkSynchronizer.stop()
                            try await sdkSynchronizer.prepareWith(seedBytes, birthday, .existingWallet)
                            try await sdkSynchronizer.start(false)
                        } catch {
                            await send(.walletReopenFailed(
                                error.localizedDescription,
                                revertTo: nil
                            ))
                            return
                        }
                    }

                    DarkircDaemonManager.shared.stop()

                    await send(.applyCompleted)
                }

            case .applyCompleted:
                return .none

            case let .walletReopenFailed(message, revertTo):
                if let revertTo {
                    state.torForWallet = revertTo
                    state.torForChat = revertTo
                    userStoredPreferences.setTorForWalletEnabled(revertTo)
                    userStoredPreferences.setTorForChatEnabled(revertTo)
                }
                state.walletRestartError = "Restart required: \(message)"
                return .none

            case .doneTapped:
                return .send(.applyAndReconnect)

            case .delegate:
                return .none
            }
        }
    }

    // ── Arti lifecycle resolution (matches AppTorCoordinator logic) ────────
    private func resolveArtiLifecycle(state: inout State) -> Effect<Action> {
        if state.isTorEnabled && state.isUsingEmbedded {
            if state.artiStatus == .stopped || state.artiStatus == .failed {
                return .send(.startArti)
            }
        } else if !state.isTorEnabled || !state.isUsingEmbedded {
            if state.artiStatus == .connected || state.artiStatus == .bootstrapping {
                return .send(.stopArti)
            }
        }
        return .none
    }

    private func reopenWalletIfPresent(previousWalletTor: Bool) -> Effect<Action> {
        guard (try? walletStorage.areKeysPresent()) == true else { return .none }
        return .run { send in
            do {
                let storedWallet = try walletStorage.exportWallet()
                let birthday = storedWallet.birthday?.value() ?? 0
                let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                sdkSynchronizer.stop()
                try await sdkSynchronizer.prepareWith(seedBytes, birthday, .existingWallet)
                try await sdkSynchronizer.start(false)
            } catch {
                await send(.walletReopenFailed(error.localizedDescription, revertTo: previousWalletTor))
            }
        }
    }

    public init() {}
}
