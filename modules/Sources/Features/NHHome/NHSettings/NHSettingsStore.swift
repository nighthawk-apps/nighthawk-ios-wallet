//
//  NHSettingsStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import AppVersion
import ComposableArchitecture
import Generated
import SwiftUI

public struct NHSettingsReducer: ReducerProtocol {
    public struct State: Equatable {
        public enum Destination: String, CaseIterable, Equatable {
            case notifications
            case fiatCurrency
            case security
            case backup
            case rescan
            case changeServer
            case externalServices
            case about
        }
        
        public var destination: Destination?
        
        public var appVersion: String
        
        public var notifications: NotificationsReducer.State
        public var fiat: FiatReducer.State
        public var security: SecurityReducer.State
        public var backup: BackupReducer.State
        public var rescan: RescanReducer.State
        public var changeServer: ChangeServerReducer.State
        public var externalServices: ExternalServicesReducer.State
        public var about: AboutReducer.State
    }
    
    public enum Action: Equatable {
        case notifications(NotificationsReducer.Action)
        case fiat(FiatReducer.Action)
        case security(SecurityReducer.Action)
        case backup(BackupReducer.Action)
        case rescan(RescanReducer.Action)
        case changeServer(ChangeServerReducer.Action)
        case externalServices(ExternalServicesReducer.Action)
        case about(AboutReducer.Action)
        case onAppear
        case updateDestination(State.Destination?)
    }
    
    @Dependency(\.appVersion) var appVersion
    
    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.notifications, action: /Action.notifications) {
            NotificationsReducer()
        }
        
        Scope(state: \.fiat, action: /Action.fiat) {
            FiatReducer()
        }
        
        Scope(state: \.security, action: /Action.security) {
            SecurityReducer()
        }
        
        Scope(state: \.backup, action: /Action.backup) {
            BackupReducer()
        }
        
        Scope(state: \.rescan, action: /Action.rescan) {
            RescanReducer()
        }
        
        Scope(state: \.changeServer, action: /Action.changeServer) {
            ChangeServerReducer()
        }
        
        Scope(state: \.externalServices, action: /Action.externalServices) {
            ExternalServicesReducer()
        }
        
        Scope(state: \.about, action: /Action.about) {
            AboutReducer()
        }
        
        Reduce { state, action in
            switch action {
            case let .updateDestination(destination):
                state.destination = destination
                return .none
            case .onAppear:
                state.appVersion = appVersion.appVersion()
                return .none
            case .notifications, .fiat, .security, .backup, .rescan, .changeServer, .externalServices, .about:
                return .none
            }
        }
    }
}

// MARK: - Placeholder
extension NHSettingsReducer.State {
    public static var placeholder: Self {
        .init(
            appVersion: "1.0.0",
            notifications: .placeholder,
            fiat: .placeholder,
            security: .placeholder,
            backup: .placeholder,
            rescan: .placeholder,
            changeServer: .placeholder,
            externalServices: .placeholder,
            about: .placeholder
        )
    }
}

extension Store<NHSettingsReducer.State, NHSettingsReducer.Action> {
    func notificationsStore() -> Store<NotificationsReducer.State, NotificationsReducer.Action> {
        self.scope(
            state: \.notifications,
            action: Action.notifications
        )
    }
    
    func fiatStore() -> Store<FiatReducer.State, FiatReducer.Action> {
        self.scope(
            state: \.fiat,
            action: Action.fiat
        )
    }
    
    func securityStore() -> Store<SecurityReducer.State, SecurityReducer.Action> {
        self.scope(
            state: \.security,
            action: Action.security
        )
    }
    
    func backupStore() -> Store<BackupReducer.State, BackupReducer.Action> {
        self.scope(
            state: \.backup,
            action: Action.backup
        )
    }
    
    func rescanStore() -> Store<RescanReducer.State, RescanReducer.Action> {
        self.scope(
            state: \.rescan,
            action: Action.rescan
        )
    }
    
    func changeServerStore() -> Store<ChangeServerReducer.State, ChangeServerReducer.Action> {
        self.scope(
            state: \.changeServer,
            action: Action.changeServer
        )
    }
    
    func externalServicesStore() -> Store<ExternalServicesReducer.State, ExternalServicesReducer.Action> {
        self.scope(
            state: \.externalServices,
            action: Action.externalServices
        )
    }
    
    func aboutStore() -> Store<AboutReducer.State, AboutReducer.Action> {
        self.scope(
            state: \.about,
            action: Action.about
        )
    }
}

extension ViewStore<NHSettingsReducer.State, NHSettingsReducer.Action> {
    func bindingForDestination(_ destination: NHSettingsReducer.State.Destination) -> Binding<Bool> {
        self.binding(
            get: { $0.destination == destination },
            send: { isActive in
                return .updateDestination(isActive ? destination : nil)
            }
        )
    }
}

// MARK: - Destination Identifiable and helper properties
extension NHSettingsReducer.State.Destination: Identifiable {
    public var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .notifications:
            return L10n.Nighthawk.SettingsTab.notificationsTitle
        case .fiatCurrency:
            return L10n.Nighthawk.SettingsTab.fiatTitle
        case .security:
            return L10n.Nighthawk.SettingsTab.securityTitle
        case .backup:
            return L10n.Nighthawk.SettingsTab.backupTitle
        case .rescan:
            return L10n.Nighthawk.SettingsTab.rescanTitle
        case .changeServer:
            return L10n.Nighthawk.SettingsTab.changeServerTitle
        case .externalServices:
            return L10n.Nighthawk.SettingsTab.externalServicesTitle
        case .about:
            return L10n.Nighthawk.SettingsTab.aboutTitle
        }
    }
    
    var subtitle: String {
        switch self {
        case .notifications:
            return L10n.Nighthawk.SettingsTab.notificationsSubtitle
        case .fiatCurrency:
            return L10n.Nighthawk.SettingsTab.fiatSubtitle
        case .security:
            return L10n.Nighthawk.SettingsTab.securitySubtitle
        case .backup:
            return L10n.Nighthawk.SettingsTab.backupSubtitle
        case .rescan:
            return L10n.Nighthawk.SettingsTab.rescanSubtitle
        case .changeServer:
            return L10n.Nighthawk.SettingsTab.changeServerSubtitle
        case .externalServices:
            return L10n.Nighthawk.SettingsTab.externalServicesSubtitle
        case .about:
            return ""
        }
    }
    
    var image: Image {
        switch self {
        case .notifications:
            return Asset.Assets.Icons.Nighthawk.notifications.image
        case .fiatCurrency:
            return Asset.Assets.Icons.Nighthawk.fiat.image
        case .security:
            return Asset.Assets.Icons.Nighthawk.security.image
        case .backup:
            return Asset.Assets.Icons.Nighthawk.backup.image
        case .rescan:
            return Asset.Assets.Icons.Nighthawk.rescan.image
        case .changeServer:
            return Asset.Assets.Icons.Nighthawk.server.image
        case .externalServices:
            return Asset.Assets.Icons.Nighthawk.services.image
        case .about:
            return Asset.Assets.Icons.Nighthawk.about.image
        }
    }
}
