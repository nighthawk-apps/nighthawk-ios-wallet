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

public struct ChangeServer: Reducer {
    let zcashNetwork: ZcashNetwork
    
    public struct State: Equatable {
        public enum LightwalletdOption: String, Equatable, CaseIterable, Identifiable, Hashable {
            case `default`
            case custom
            
            public var id: String { rawValue }
        }
        
        @PresentationState public var alert: AlertState<Action.Alert>?
        @BindingState public var lightwalletdOption: LightwalletdOption = .default
        @BindingState public var customLightwalletdServer: String = ""
        public var defaultLightwalletdServer = ""
        
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
            
            return isChanged && (lightwalletdOption == .default || isValidHostAndPort)
        }
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case onAppear
        case saveTapped
        
        public enum Alert: Equatable {}
    }
    
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.zcashSDKEnvironment) var zcashSdkEnvironment
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case .onAppear:
                let defaultEndpoint = zcashSdkEnvironment.defaultEndpoint()
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
                userStoredPreferences.setIsUsingCustomLightwalletd(state.lightwalletdOption == .custom)
                userStoredPreferences.setCustomLightwalletdServer(state.lightwalletdOption == .custom ? state.customLightwalletdServer : nil)
                state.alert = .relaunchRequired()
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }
}

// MARK: - Alerts
extension AlertState where Action == ChangeServer.Action.Alert {
    public static func relaunchRequired() -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.ChangeServer.Alert.RelaunchNeeded.title)
        } actions: {
            ButtonState {
                TextState(L10n.General.ok)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.ChangeServer.Alert.RelaunchNeeded.message)
        }
    }
}

extension ViewStoreOf<ChangeServer> {
    func validateCustomLightwalletdServer() -> NighthawkTextFieldValidationState {
        self.isValidHostAndPort ? .valid : .invalid(error: L10n.Nighthawk.SettingsTab.ChangeServer.Custom.invalidLightwalletd)
    }
}

