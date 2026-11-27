//
//  Advanced.swift
//
//
//  Created by Matthew Watt on 8/3/23.
//

import ComposableArchitecture
import DarkfiCore
import Generated
import MnemonicClient
import Models
import SDKSynchronizer
import UserPreferencesStorage
import UIKit
import WalletStorage

@Reducer
public struct Advanced {
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var selectedScreenMode: NighthawkSetting.ScreenMode = .off
        public var selectedAppIcon: NighthawkSetting.AppIcon = .default
        public var theme: NighthawkSetting.Theme = .default
        public var disableDirectConnection = false
        public var showBanditSettings = false

        public var supportsAlternateIcons: Bool {
            UIApplication.shared.supportsAlternateIcons
        }

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case appIconResponse(success: Bool)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case deleteWalletTapped
        case disableDirectConnectionToggled(Bool)
        case onAppear
        case nukeLocalDatabasesTapped

        @CasePathable
        public enum Alert: Equatable {
            case deleteWalletConfirmed
            case disableDirectConnectionConfirmed
            case notifyAppRelaunchNeeded
            case nukeLocalDatabasesConfirmed
        }

        public enum Delegate: Equatable {
            case deleteWallet
            case nukeLocalDatabases
        }
    }

    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.mnemonic) var mnemonic

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .alert(.presented(.deleteWalletConfirmed)):
                return .send(.delegate(.deleteWallet))
            case .alert(.presented(.disableDirectConnectionConfirmed)):
                let wasDirectOrOverride = SessionPrivacyOverride.forceDirectThisSession
                    || userStoredPreferences.walletPrivacyNetwork() == .direct
                state.disableDirectConnection = true
                userStoredPreferences.setDisableDirectConnection(true)
                SessionPrivacyOverride.clear()
                TransportHooks.clearSessionOverride()
                TransportHooks.setDirectDisabled(true)
                if wasDirectOrOverride {
                    let torPort = Int32(userStoredPreferences.torSocksPort() ?? "9050") ?? 9050
                    TransportHooks.apply(
                        kind: 0,
                        nymPort: Int32(NighthawkSetting.PrivacyNetwork.nymSocksPort),
                        torPort: torPort
                    )
                    return .run { [walletStorage, sdkSynchronizer, mnemonic] _ in
                        DarkircDaemonManager.shared.stop()
                        await Task.detached(priority: .utility) {
                            _ = DarkfiFfiSafe.startNymProxySafely(
                                socksPort: NighthawkSetting.PrivacyNetwork.nymSocksPort
                            )
                        }.value
                        try? await WalletTransportReprepare.reprepareExisting(
                            walletStorage: walletStorage,
                            sdkSynchronizer: sdkSynchronizer,
                            mnemonic: mnemonic
                        )
                    }
                }
                return .none
            case let .disableDirectConnectionToggled(enabled):
                if enabled {
                    state.alert = AlertState.warnBeforeDisablingDirectConnection
                } else {
                    state.disableDirectConnection = false
                    userStoredPreferences.setDisableDirectConnection(false)
                    TransportHooks.setDirectDisabled(false)
                }
                return .none
            case .alert(.presented(.notifyAppRelaunchNeeded)):
                state.alert = .notifyAppRelaunchNeeded
                return .none
            case .alert(.presented(.nukeLocalDatabasesConfirmed)):
                return .send(.delegate(.nukeLocalDatabases))
            case .appIconResponse(success: true):
                userStoredPreferences.setAppIcon(state.selectedAppIcon)
                return .none
            case .appIconResponse(success: false):
                state.selectedAppIcon = userStoredPreferences.appIcon()
                return .none
            case .delegate:
                return .none
            case .onAppear:
                state.selectedScreenMode = userStoredPreferences.screenMode()
                state.selectedAppIcon = userStoredPreferences.appIcon()
                let storedTheme = userStoredPreferences.theme()
                state.theme = storedTheme == .default ? .cyberpunk : storedTheme
                state.disableDirectConnection = userStoredPreferences.disableDirectConnection()
                state.showBanditSettings = userStoredPreferences.isBandit()
                return .none
            case .deleteWalletTapped:
                state.alert = AlertState.warnBeforeDeletingWallet
                return .none
            case .nukeLocalDatabasesTapped:
                state.alert = AlertState.warnBeforeNukingLocalDatabases
                return .none
            case .binding(\.selectedAppIcon):
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
            case .binding(\.selectedScreenMode):
                userStoredPreferences.setScreenMode(state.selectedScreenMode)
                UIApplication.shared.isIdleTimerDisabled = state.selectedScreenMode == .keepOn
                return .none
            case .binding(\.theme):
                userStoredPreferences.setTheme(state.theme)
                return .none
            case .alert, .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
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

    public static var warnBeforeNukingLocalDatabases: AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeLocalDatabases.Alert.title)
        } actions: {
            ButtonState(role: .destructive, action: .nukeLocalDatabasesConfirmed) {
                TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeLocalDatabases.Alert.confirm)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Advanced.NukeLocalDatabases.Alert.message)
        }
    }

    public static var warnBeforeDisablingDirectConnection: AlertState {
        AlertState {
            TextState("Disable Direct Connections")
        } actions: {
            ButtonState(role: .destructive, action: .disableDirectConnectionConfirmed) {
                TextState("Disable Direct")
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState("Permanently block Direct (clearnet) fallback and \"Continue without Nym\" across wallet and chat. All traffic will require Nym or Tor.")
        }
    }
}
