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

public struct Advanced: Reducer {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        
        @BindingState public var selectedScreenMode: NighthawkSetting.ScreenMode = .off
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case deleteWalletTapped
        case onAppear
        
        public enum Alert: Equatable {
            case deleteWalletConfirmed
        }
        
        public enum Delegate: Equatable {
            case deleteWallet
        }
    }
    
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .alert(.presented(.deleteWalletConfirmed)):
                return .send(.delegate(.deleteWallet))
            case .delegate:
                return .none
            case .deleteWalletTapped:
                state.alert = AlertState.warnBeforeDeletingWallet
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
    public static var warnBeforeDeletingWallet: AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.lastWarningTitle)
        } actions: {
            ButtonState(role: .destructive, action: .deleteWalletConfirmed) {
                TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.title)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.lastWarningMessage)
        }
    }
}
