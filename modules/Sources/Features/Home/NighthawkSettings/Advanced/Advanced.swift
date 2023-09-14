//
//  Advanced.swift
//  
//
//  Created by Matthew Watt on 8/3/23.
//

import ComposableArchitecture
import Generated
import Models
import UserPreferencesStorage
import UIKit

public struct Advanced: ReducerProtocol {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        
        @BindingState public var selectedScreenMode: NighthawkSetting.ScreenMode = .off
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case nukeWalletTapped
        case onAppear
        
        public enum Alert: Equatable {
            case nukeWalletConfirmed
        }
        
        public enum Delegate: Equatable {
            case nukeWallet
        }
    }
    
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerProtocolOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .alert(.presented(.nukeWalletConfirmed)):
                return .run { send in await send(.delegate(.nukeWallet)) }
            case .delegate:
                return .none
            case .nukeWalletTapped:
                state.alert = AlertState.warnBeforeNukingWallet
                return .none
            case .onAppear:
                state.selectedScreenMode = userStoredPreferences.screenMode()
                return .none
            case .binding(\.$selectedScreenMode):
                userStoredPreferences.setScreenMode(state.selectedScreenMode)
                UIApplication.shared.isIdleTimerDisabled = state.selectedScreenMode == .keepOn
                return .none
            case .alert, .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    public init() {}
}

// MARK: Alerts
extension AlertState where Action == Advanced.Action.Alert {
    public static var warnBeforeNukingWallet: AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.lastWarningTitle)
        } actions: {
            ButtonState(role: .destructive, action: .nukeWalletConfirmed) {
                TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.title)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.lastWarningMessage)
        }
    }
}
