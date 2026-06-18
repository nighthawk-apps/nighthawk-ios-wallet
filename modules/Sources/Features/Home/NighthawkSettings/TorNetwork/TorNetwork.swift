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
import SDKSynchronizer
import UserPreferencesStorage

@Reducer
public struct TorNetwork {
    @ObservableState
    public struct State: Equatable {
        // ── Routing toggle (single app-wide toggle matching Android) ────
        public var torForWallet: Bool = false
        public var torForChat: Bool = false
        
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
        case doneTapped
        
        // Delegate
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case dismiss
        }
    }
    
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
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
                state.torForWallet = enabled
                state.torForChat = enabled
                userStoredPreferences.setTorForWalletEnabled(enabled)
                userStoredPreferences.setTorForChatEnabled(enabled)
                return resolveArtiLifecycle(state: &state)
                
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
                    let started = DarkfiFfiSafe.startArtiProxySafely(socksPort: port)
                    await send(.artiBootstrapProgressUpdated(1.0))
                    let status: State.ArtiStatus = started && DarkfiFfiSafe.isArtiRunning()
                        ? .connected
                        : .failed
                    await send(.artiStatusChanged(status))
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
                
                let torForWallet = state.torForWallet
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
                    
                    if torForWallet {
                        sdkSynchronizer.stop()
                        try? await sdkSynchronizer.start(false)
                    }
                    
                    DarkircDaemonManager.shared.stop()
                    
                    await send(.applyCompleted)
                }
                
            case .applyCompleted:
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
    
    public init() {}
}
