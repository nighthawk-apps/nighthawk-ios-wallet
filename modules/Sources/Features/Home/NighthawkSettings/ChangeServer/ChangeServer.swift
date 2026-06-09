//
//  ChangeServer.swift → AddServer.swift
//  stealth
//
//  DarkFi: Allows user to add a custom server address for the daemon to connect to.
//  DarkFi has NO LightWallet endpoints. The daemon connects directly to the P2P network.
//  This feature lets the user configure a custom seed node or relay.
//

import ComposableArchitecture
import Foundation
import Generated
import Models
import UIComponents
import UserPreferencesStorage
import Utils

@Reducer
public struct ChangeServer {
    @ObservableState
    public struct State: Equatable {
        public enum ServerOption: String, Equatable, CaseIterable, Identifiable, Hashable {
            case `default`
            case custom
            
            public var id: String { rawValue }
        }
        
        @Presents public var alert: AlertState<Action.Alert>?
        public var serverOption: ServerOption = .default
        public var customServerAddress: String = ""
        public var defaultServerInfo = "DarkFi P2P Network (automatic)"
        public var isChangingServer = false
        /// Show warning when using a non-standard port
        public var showPortWarning = false
        
        public var isValidHostAndPort: Bool {
            if serverOption == .default { return true }
            
            let validHostAndPort = #/^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]):([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/#
            
            return customServerAddress.contains(validHostAndPort)
        }
        
        /// DarkFi mainnet port is 8345, testnet is 18345.
        public var isExpectedDarkFiPort: Bool {
            guard serverOption == .custom else { return true }
            let components = customServerAddress.split(separator: ":")
            guard let portStr = components.last, let port = Int(portStr) else { return false }
            return port == 8345 || port == 18345
        }
        
        public var canSave: Bool {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            let isChanged = userStoredPreferences.isUsingCustomLightwalletd() && serverOption == .default
            || !userStoredPreferences.isUsingCustomLightwalletd() && serverOption == .custom
            || (serverOption == .custom && userStoredPreferences.customLightwalletdServer() != customServerAddress)
            
            return isChanged && (serverOption == .default || isValidHostAndPort) && !isChangingServer
        }
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case onAppear
        case saveTapped
        case portWarningConfirmed
        case portWarningCancelled
        case changeFailed(error: DarkFiError, previousIsUsingCustom: Bool, previousCustomServer: String?)
        case changeSucceeded
        
        public enum Alert: Equatable {}
    }
    
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case .onAppear:
                state.defaultServerInfo = "127.0.0.1:18345 (darkfid testnet 0.3)"
                if userStoredPreferences.isUsingCustomLightwalletd(),
                   let customServer = userStoredPreferences.customLightwalletdServer() {
                    state.serverOption = .custom
                    state.customServerAddress = customServer
                } else {
                    state.serverOption = .default
                }
                return .none
            case .saveTapped:
                guard state.canSave else { return .none }
                
                // Check for non-standard port and warn
                if state.serverOption == .custom && !state.isExpectedDarkFiPort {
                    state.showPortWarning = true
                    return .none
                }
                
                return .send(.portWarningConfirmed)
                
            case .portWarningCancelled:
                state.showPortWarning = false
                return .none
                
            case .portWarningConfirmed:
                state.showPortWarning = false
                state.isChangingServer = true
                
                let oldIsUsingCustom = userStoredPreferences.isUsingCustomLightwalletd()
                let oldCustomServer = userStoredPreferences.customLightwalletdServer()
                
                userStoredPreferences.setIsUsingCustomLightwalletd(state.serverOption == .custom)
                userStoredPreferences.setCustomLightwalletdServer(state.serverOption == .custom ? state.customServerAddress : nil)
                
                let isCustom = state.serverOption == .custom
                let customAddress = state.customServerAddress
                
                return .run { send in
                    // Save the endpoint to UserDefaults so WalletHandleManager picks it up
                    if isCustom && !customAddress.isEmpty {
                        let endpoint = "tcp://\(customAddress)"
                        UserDefaults.standard.set(endpoint, forKey: "darkfi_server_endpoint")
                    } else {
                        UserDefaults.standard.removeObject(forKey: "darkfi_server_endpoint")
                    }
                    
                    try await mainQueue.sleep(for: .seconds(0.5))
                    await send(.changeSucceeded)
                }
            case let .changeFailed(error, previousIsUsingCustom, previousCustomServer):
                state.isChangingServer = false
                userStoredPreferences.setIsUsingCustomLightwalletd(previousIsUsingCustom)
                userStoredPreferences.setCustomLightwalletdServer(previousCustomServer)
                state.alert = AlertState.serverChangeFailed(error)
                return .none
            case .changeSucceeded:
                state.isChangingServer = false
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    public init() {}
}

// MARK: - Alerts
extension AlertState where Action == ChangeServer.Action.Alert {
    public static func serverChangeFailed(_ error: DarkFiError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.ChangeServer.Alert.ChangeServerFailed.title)
        } actions: {
            ButtonState {
                TextState(L10n.General.ok)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.ChangeServer.Alert.ChangeServerFailed.message(error.message, 0))
        }
    }
}
