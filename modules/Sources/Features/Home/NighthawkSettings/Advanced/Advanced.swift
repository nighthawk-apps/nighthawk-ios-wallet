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
        @BindingState public var selectedAppIcon: NighthawkSetting.AppIcon = .default
        public var showBanditSettings: Bool {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return userStoredPreferences.isBandit()
        }
        
        public var supportsAlternateIcons: Bool {
            UIApplication.shared.supportsAlternateIcons
        }

        public init() {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            self.selectedScreenMode = userStoredPreferences.screenMode()
            self.selectedAppIcon = userStoredPreferences.appIcon()
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case appIconResponse(success: Bool)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case deleteWalletTapped
        
        public enum Alert: Equatable {
            case deleteWalletConfirmed
            case notifyAppRelaunchNeeded
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
            case .alert(.presented(.notifyAppRelaunchNeeded)):
                state.alert = .notifyAppRelaunchNeeded
                return .none
            case .appIconResponse(success: true):
                userStoredPreferences.setAppIcon(state.selectedAppIcon)
                return .none
            case .appIconResponse(success: false):
                state.selectedAppIcon = userStoredPreferences.appIcon()
                return .none
            case .delegate:
                return .none
            case .deleteWalletTapped:
                state.alert = AlertState.warnBeforeDeletingWallet
                return .none
            case .binding(\.$selectedAppIcon):
                return .run { @MainActor [selectedIcon = state.selectedAppIcon] send in
                    do {
                        let iconName: String? = if selectedIcon == .default {
                            nil
                        } else {
                            selectedIcon.rawValue
                        }
                        
                        try await UIApplication.shared.setAlternateIconName(iconName)
                        send(.appIconResponse(success: true))
                    } catch {
                        send(.appIconResponse(success: false))
                    }
                }
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
            TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.Alert.LastWarning.title)
        } actions: {
            ButtonState(role: .destructive, action: .notifyAppRelaunchNeeded) {
                TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.title)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.Alert.LastWarning.message)
        }
    }
    
    public static var notifyAppRelaunchNeeded: AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.Alert.RelaunchRequired.title)
        } actions: {
            ButtonState(role: .destructive, action: .deleteWalletConfirmed) {
                TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.Alert.RelaunchRequired.confirm)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.Alert.RelaunchRequired.message)
        }
    }
}
