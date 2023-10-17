//
//  ChangeServer.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import Generated
import Models
import UserPreferencesStorage

public struct ChangeServer: Reducer {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        @BindingState public var lightwalletdServer: NighthawkSetting.LightwalletdServer
        
        public init() {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            self.lightwalletdServer = userStoredPreferences.lightwalletdServer()
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        
        public enum Alert: Equatable {}
    }
    
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case .binding(\.$lightwalletdServer):
                userStoredPreferences.setLightwalletdServer(state.lightwalletdServer)
                state.alert = .relaunchRequired()
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    public init() {}
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
