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

public struct NighthawkSettings: Reducer {
    let zcashNetwork: ZcashNetwork
    
    public struct State: Equatable {
        @PresentationState public var destination: Destination.State?
        
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
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case rowTapped(NighthawkSettings.State.Screen)
        
        public enum Delegate: Equatable {
            case goTo(NighthawkSettings.State.Screen)
        }
    }
    
    public struct Destination: Reducer {
        public enum State: Equatable {
            case alert(AlertState<Action.Alert>)
        }
        
        public enum Action: Equatable {
            case alert(Alert)
            
            public enum Alert: Equatable {
                case viewSeed
            }
        }
        
        public var body: some ReducerOf<Self> {
            Reduce { _, _ in .none }
        }
        
        public init() {}
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
            case .destination(.dismiss):
                return .none
            case .destination(.presented(.alert(.viewSeed))):
                return .run { send in await send(.delegate(.goTo(.backup))) }
            case .onAppear:
                state.appVersion = appVersion.appVersion()
                let context = localAuthenticationContext()
                // biometryType is not populated until canEvaluatePolicy is called: https://developer.apple.com/documentation/localauthentication/lacontext/2867583-biometrytype
                // So call it before trying to fetch the biometryType.
                _ = try? context.canEvaluatePolicy(.deviceOwnerAuthentication)
                state.biometryType = context.biometryType()
                return .none
            case .rowTapped(.backup):
                state.destination = .alert(AlertState.confirmViewSeedWords())
                return .none
            case let .rowTapped(screen):
                return .run { send in await send(.delegate(.goTo(screen)))}
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }
}

// MARK: Alerts
extension AlertState where Action == NighthawkSettings.Destination.Action.Alert {
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
}
