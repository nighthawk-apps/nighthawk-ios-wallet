//
//  ChangeServer.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import Generated
import Models
import UIComponents
import UserPreferencesStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct ChangeServer {    
    @ObservableState
    public struct State: Equatable {
        public enum LightwalletdOption: String, Equatable, CaseIterable, Identifiable, Hashable {
            case `default`
            case custom
            
            public var id: String { rawValue }
        }
        
        @Presents public var alert: AlertState<Action.Alert>?
        public var lightwalletdOption: LightwalletdOption = .default
        public var customLightwalletdServer: String = ""
        public var defaultLightwalletdServer = ""
        public var isChangingServer = false
        
        public var isValidHostAndPort: Bool {
            if lightwalletdOption == .default { return true }
            
            let validHostAndPort = #/^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]):([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/#
            
            return customLightwalletdServer.contains(validHostAndPort)
        }
        
        public var canSave: Bool {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            let isChanged = userStoredPreferences.isUsingCustomLightwalletd() && lightwalletdOption == .default
            || !userStoredPreferences.isUsingCustomLightwalletd() && lightwalletdOption == .custom
            || (lightwalletdOption == .custom && userStoredPreferences.customLightwalletdServer() != customLightwalletdServer)
            
            return isChanged && (lightwalletdOption == .default || isValidHostAndPort) && !isChangingServer
        }
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case onAppear
        case saveTapped
        case changeFailed(error: ZcashError, previousIsUsingCustomLightwalletd: Bool, previousCustomLightwalletd: String?)
        case changeSucceeded
        
        public enum Alert: Equatable {}
    }
    
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.zcashSDKEnvironment) var zcashSdkEnvironment
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case .onAppear:
                let defaultEndpoint = zcashSdkEnvironment.defaultEndpoint
                state.defaultLightwalletdServer = "\(defaultEndpoint.host):\(defaultEndpoint.port)"
                if userStoredPreferences.isUsingCustomLightwalletd(),
                   let customServer = userStoredPreferences.customLightwalletdServer() {
                    state.lightwalletdOption = .custom
                    state.customLightwalletdServer = customServer
                } else {
                    state.lightwalletdOption = .default
                }
                return .none
            case .saveTapped:
                guard state.canSave else { return .none }
                
                state.isChangingServer = true
                
                let oldIsUsingCustomLightwalletd = userStoredPreferences.isUsingCustomLightwalletd()
                let oldCustomLightwalletdServer = userStoredPreferences.customLightwalletdServer()
                
                userStoredPreferences.setIsUsingCustomLightwalletd(state.lightwalletdOption == .custom)
                userStoredPreferences.setCustomLightwalletdServer(state.lightwalletdOption == .custom ? state.customLightwalletdServer : nil)
                
                return .run { send in
                    do {
                        let lightWalletEndpoint = zcashSdkEnvironment.endpoint
                        try await sdkSynchronizer.switchToEndpoint(lightWalletEndpoint)
                        try await mainQueue.sleep(for: .seconds(1))
                        await send(.changeSucceeded)
                    } catch {
                        await send(
                            .changeFailed(
                                error: error.toZcashError(),
                                previousIsUsingCustomLightwalletd: oldIsUsingCustomLightwalletd,
                                previousCustomLightwalletd: oldCustomLightwalletdServer
                            )
                        )
                    }
                }
            case let .changeFailed(error, previousIsUsingCustom, previousCustomLightwalletd):
                state.isChangingServer = false
                userStoredPreferences.setIsUsingCustomLightwalletd(previousIsUsingCustom)
                userStoredPreferences.setCustomLightwalletdServer(previousCustomLightwalletd)
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
    public static func serverChangeFailed(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.ChangeServer.Alert.ChangeServerFailed.title)
        } actions: {
            ButtonState {
                TextState(L10n.General.ok)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.ChangeServer.Alert.ChangeServerFailed.message(error.message, error.code.rawValue))
        }
    }
}

