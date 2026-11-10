//
//  NighthawkSettings.swift
//  stealth
//
//  Created by Matthew Watt on 5/5/23.
//

import AppVersion
import ComposableArchitecture
import Generated
import LocalAuthentication
import LocalAuthenticationClient
import MnemonicClient
import Models
import RecoveryPhraseDisplay
import SwiftUI
import WalletStorage

@Reducer
public struct NighthawkSettings {
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?

        public var appVersion: String = "1.0.0"
        public var biometryType: LABiometryType = .none
        /// Settings screen shown in the right pane when the window is wide.
        @Presents public var foldDetail: NighthawkSettingsFoldDetail.State?

        public enum Screen: Equatable {
            case about
            case advanced
            case backup
            case changeServer
            case chatSettings
            case fiat
            case notifications
            case rescan
            case security
            case torNetwork
        }

        public init() {}
    }

    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        case foldClosed
        case foldDetail(PresentationAction<NighthawkSettingsFoldDetail.Action>)
        case foldRowTapped(NighthawkSettings.State.Screen)
        case onAppear
        case rescanTapped
        case rowTapped(NighthawkSettings.State.Screen)

        public enum Alert: Equatable {
            case viewSeed
            case wipe
        }

        public enum Delegate: Equatable {
            case rescan
            case goTo(NighthawkSettings.State.Screen)
            case deleteWallet
            case nukeLocalDatabases
            case fetchLatestFiatCurrency
        }
    }

    @Dependency(\.appVersion) var appVersion
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.walletStorage) var walletStorage

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .alert(.dismiss):
                return .none
            case .alert(.presented(.viewSeed)):
                return .run { send in
                    let context = localAuthenticationContext()
                    do {
                        if try context.canEvaluatePolicy(.deviceOwnerAuthentication) {
                            let response = try await context.evaluatePolicy(
                                .deviceOwnerAuthentication,
                                L10n.Nighthawk.SettingsTab.Backup.viewSeedWarningAlertTitle
                            )
                            if response {
                                await send(.delegate(.goTo(.backup)))
                            }
                        } else {
                            await send(.delegate(.goTo(.backup)))
                        }
                    } catch {
                        // Authentication failed or canceled - do not show seed
                    }
                }
            case .alert(.presented(.wipe)):
                return .send(.delegate(.rescan))
            case .onAppear:
                state.appVersion = appVersion.appVersion()
                let context = localAuthenticationContext()
                // biometryType is not populated until canEvaluatePolicy is called: https://developer.apple.com/documentation/localauthentication/lacontext/2867583-biometrytype
                // So call it before trying to fetch the biometryType.
                _ = try? context.canEvaluatePolicy(.deviceOwnerAuthentication)
                state.biometryType = context.biometryType()
                return .none
            case .rescanTapped:
                state.alert = .confirmRescan()
                return .none
            case .foldClosed:
                state.foldDetail = nil
                return .none
            case .foldDetail(.dismiss):
                state.foldDetail = nil
                return .none
            case .foldDetail(.presented(.advanced(.delegate(.deleteWallet)))):
                return .send(.delegate(.deleteWallet))
            case .foldDetail(.presented(.advanced(.delegate(.nukeLocalDatabases)))):
                return .send(.delegate(.nukeLocalDatabases))
            case .foldDetail(.presented(.fiat(.delegate(.fetchLatestFiatCurrency)))):
                return .send(.delegate(.fetchLatestFiatCurrency))
            case .foldDetail(.presented(.torNetwork(.delegate(.dismiss)))):
                state.foldDetail = nil
                return .none
            case .foldDetail:
                return .none
            case let .foldRowTapped(screen):
                return openFold(screen, state: &state)
            case .rowTapped(.backup):
                state.alert = .confirmViewSeedWords()
                return .none
            case let .rowTapped(screen):
                return .send(.delegate(.goTo(screen)))
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$foldDetail, action: \.foldDetail)
    }

    private func openFold(
        _ screen: State.Screen,
        state: inout State
    ) -> Effect<Action> {
        switch screen {
        case .about:
            state.foldDetail = .about(About.State())
        case .advanced:
            state.foldDetail = .advanced(Advanced.State())
        case .backup:
            return .send(.delegate(.goTo(.backup)))
        case .changeServer:
            state.foldDetail = .changeServer(ChangeServer.State())
        case .chatSettings:
            state.foldDetail = .chatSettings(ChatSettings.State())
        case .fiat:
            state.foldDetail = .fiat(Fiat.State())
        case .notifications:
            state.foldDetail = .notifications(Notifications.State())
        case .rescan:
            state.alert = .confirmRescan()
        case .security:
            state.foldDetail = .security(Security.State())
        case .torNetwork:
            state.foldDetail = .torNetwork(TorNetwork.State())
        }
        return .none
    }

    public init() {}
}

@Reducer(state: .equatable, action: .equatable)
public enum NighthawkSettingsFoldDetail {
    case about(About)
    case advanced(Advanced)
    case changeServer(ChangeServer)
    case chatSettings(ChatSettings)
    case fiat(Fiat)
    case notifications(Notifications)
    case security(Security)
    case torNetwork(TorNetwork)
}

// MARK: Alerts
extension AlertState where Action == NighthawkSettings.Action.Alert {
    public static func confirmViewSeedWords() -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Backup.viewSeedWarningAlertTitle)
        } actions: {
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }

            ButtonState(role: .destructive, action: .viewSeed) {
                TextState(L10n.Nighthawk.SettingsTab.Backup.viewSeedWarningAlertConfirmAction)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Backup.viewSeedWarningAlertMessage)
        }
    }

    public static func confirmRescan() -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.title)
        } actions: {
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }

            ButtonState(role: .destructive, action: .wipe) {
                TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.wipe)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.message)
        }
    }
}
