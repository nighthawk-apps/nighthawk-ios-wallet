//
//  NHSettingsStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import SwiftUI

struct NHSettingsReducer: ReducerProtocol {
    struct State: Equatable {
        enum Destination: String, CaseIterable, Equatable {
            case notifications
            case fiatCurrency
            case security
            case backup
            case rescan
            case changeServer
            case externalServices
            case about
        }
        
        var destination: Destination?
        
        var appVersion: String
        
        var notifications: NotificationsReducer.State
        var fiat: FiatReducer.State
        var security: SecurityReducer.State
        var backup: BackupReducer.State
        var rescan: RescanReducer.State
    }
    
    enum Action: Equatable {
        case notifications(NotificationsReducer.Action)
        case fiat(FiatReducer.Action)
        case security(SecurityReducer.Action)
        case backup(BackupReducer.Action)
        case rescan(RescanReducer.Action)
        case onAppear
        case updateDestination(State.Destination?)
    }
    
    @Dependency(\.appVersion) var appVersion
    
    var body: some ReducerProtocol<State, Action> {
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
        
        Reduce { state, action in
            switch action {
            case let .updateDestination(destination):
                state.destination = destination
                return .none
            case .onAppear:
                state.appVersion = appVersion.appVersion()
                return .none
            case .notifications, .fiat, .security, .backup, .rescan:
                return .none
            }
        }
    }
}

// MARK: - Placeholder
extension NHSettingsReducer.State {
    static var placeholder: Self {
        .init(
            appVersion: "1.0.0",
            notifications: .placeholder,
            fiat: .placeholder,
            security: .placeholder,
            backup: .placeholder,
            rescan: .placeholder
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
    var id: String { self.rawValue }
    
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
