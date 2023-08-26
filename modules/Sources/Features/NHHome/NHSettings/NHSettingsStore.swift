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
import LocalAuthenticationHandler
import SwiftUI

public typealias NHSettingsStore = Store<NHSettingsReducer.State, NHSettingsReducer.Action>
public typealias NHSettingsViewStore = ViewStore<NHSettingsReducer.State, NHSettingsReducer.Action>

public struct NHSettingsReducer: ReducerProtocol {
    public struct Path: ReducerProtocol {
        public enum State: Equatable {
            case about(AboutReducer.State = .init())
            case advanced(AdvancedReducer.State = .init())
            case backup(BackupReducer.State = .init())
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
            case backup(BackupReducer.Action)
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
                BackupReducer()
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
        public var path = StackState<Path.State>()
        
        public var appVersion: String
        public var biometryType: LABiometryType
    }
    
    public enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case goTo(Path.State)
        case onAppear
    }
    
    @Dependency(\.appVersion) var appVersion
    @Dependency(\.localAuthentication) var localAuthentication
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .goTo(pathState):
                state.path.append(pathState)
                return .none
            case .onAppear:
                state.appVersion = appVersion.appVersion()
                state.biometryType = localAuthentication.biometryType()
                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
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

extension Store<NHSettingsReducer.State, NHSettingsReducer.Action> {
    func stackStore() -> Store<
        StackState<NHSettingsReducer.Path.State>,
        StackAction<NHSettingsReducer.Path.State, NHSettingsReducer.Path.Action>
    > {
        scope(state: \.path, action: { .path($0) })
    }
}
