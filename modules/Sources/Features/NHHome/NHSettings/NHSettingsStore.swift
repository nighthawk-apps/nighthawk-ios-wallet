//
//  NHSettingsStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import AppVersion
import ComposableArchitecture
import Generated
import LocalAuthentication
import LocalAuthenticationClient
import RecoveryPhraseDisplay
import SwiftUI

public typealias NHSettingsStore = Store<NHSettingsReducer.State, NHSettingsReducer.Action>
public typealias NHSettingsViewStore = ViewStore<NHSettingsReducer.State, NHSettingsReducer.Action>

public struct NHSettingsReducer: ReducerProtocol {
    public struct Path: ReducerProtocol {
        public enum State: Equatable {
            case about(AboutReducer.State = .init())
            case advanced(AdvancedReducer.State = .init())
            case backup(RecoveryPhraseDisplayReducer.State = .init(flow: .settings))
            case changeServer(ChangeServerReducer.State = .init())
            case externalServices(ExternalServicesReducer.State = .init())
            case fiat(FiatReducer.State = .init())
            case notifications(NotificationsReducer.State = .init())
            case rescan(RescanReducer.State = .init())
            case security(SecurityReducer.State = .init())
        }
        
        public enum Action: Equatable {
            case about(AboutReducer.Action)
            case advanced(AdvancedReducer.Action)
            case backup(RecoveryPhraseDisplayReducer.Action)
            case changeServer(ChangeServerReducer.Action)
            case externalServices(ExternalServicesReducer.Action)
            case fiat(FiatReducer.Action)
            case notifications(NotificationsReducer.Action)
            case rescan(RescanReducer.Action)
            case security(SecurityReducer.Action)
        }
        
        public var body: some ReducerProtocol<State, Action> {
            Scope(state: /State.about, action: /Action.about) {
                AboutReducer()
            }
            
            Scope(state: /State.advanced, action: /Action.advanced) {
                AdvancedReducer()
            }
            
            Scope(state: /State.backup, action: /Action.backup) {
                RecoveryPhraseDisplayReducer()
            }
            
            Scope(state: /State.changeServer, action: /Action.changeServer) {
                ChangeServerReducer()
            }
            
            Scope(state: /State.externalServices, action: /Action.externalServices) {
                ExternalServicesReducer()
            }
            
            Scope(state: /State.fiat, action: /Action.fiat) {
                FiatReducer()
            }
            
            Scope(state: /State.notifications, action: /Action.notifications) {
                NotificationsReducer()
            }
            
            Scope(state: /State.rescan, action: /Action.rescan) {
                RescanReducer()
            }
            
            Scope(state: /State.security, action: /Action.security) {
                SecurityReducer()
            }
        }
        
        public init() {}
    }
    
    public struct State: Equatable {
        @PresentationState public var destination: Destination.State?
        public var path = StackState<Path.State>()
        
        public var appVersion: String
        public var biometryType: LABiometryType
    }
    
    public enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case path(StackAction<Path.State, Path.Action>)
        case goTo(Path.State)
        case onAppear
    }
    
    public struct Destination: ReducerProtocol {
        public enum State: Equatable {
            case alert(AlertState<Action.Alert>)
        }
        
        public enum Action: Equatable {
            case alert(Alert)
            
            public enum Alert: Equatable {
                case viewSeed
            }
        }
        
        public var body: some ReducerProtocolOf<Self> {
            Reduce { _, _ in .none }
        }
        
        public init() {}
    }
    
    @Dependency(\.appVersion) var appVersion
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .destination(.dismiss):
                return .none
            case .destination(.presented(.alert(.viewSeed))):
                state.path.append(.backup())
                return .none
            case .goTo(.backup):
                state.destination = .alert(AlertState.confirmViewSeedWords())
                return .none
            case let .goTo(pathState):
                state.path.append(pathState)
                return .none
            case .onAppear:
                state.appVersion = appVersion.appVersion()
                let context = localAuthenticationContext()
                // biometryType is not populated until canEvaluatePolicy is called: https://developer.apple.com/documentation/localauthentication/lacontext/2867583-biometrytype
                // So call it before trying to fetch the biometryType.
                _ = try? context.canEvaluatePolicy(.deviceOwnerAuthentication)
                state.biometryType = context.biometryType()
                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

// MARK: Alerts
extension AlertState where Action == NHSettingsReducer.Destination.Action.Alert {
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

// MARK: - Placeholder
extension NHSettingsReducer.State {
    public static var placeholder: Self {
        .init(
            appVersion: "1.0.0",
            biometryType: .none
        )
    }
}
