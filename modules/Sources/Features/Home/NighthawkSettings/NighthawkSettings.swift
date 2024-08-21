//
//  NighthawkSettings.swift
//  secant
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
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct NighthawkSettings {    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        
        public var appVersion: String = "1.0.0"
        public var biometryType: LABiometryType = .none
        
        public enum Screen: Equatable {
            case about
            case advanced
            case backup
            case changeServer
            case externalServices
            case fiat
            case notifications
            case rescan
            case security
        }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
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
        }
    }
    
    @Dependency(\.appVersion) var appVersion
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .alert(.dismiss):
                return .none
            case .alert(.presented(.viewSeed)):
                return .send(.delegate(.goTo(.backup)))
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
            case .rowTapped(.backup):
                state.alert = .confirmViewSeedWords()
                return .none
            case let .rowTapped(screen):
                return .send(.delegate(.goTo(screen)))
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    public init() {}
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
