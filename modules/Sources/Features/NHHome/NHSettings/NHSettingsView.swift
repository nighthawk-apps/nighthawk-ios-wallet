//
//  NHSettingsView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

struct NHSettingsView: View {
    let store: Store<NHSettingsReducer.State, NHSettingsReducer.Action>
    
    var body: some View {
        NavigationStackStore(store.stackStore()) {
            WithViewStore(store) { viewStore in
                ScrollView([.vertical], showsIndicators: false) {
                    NighthawkLogo(spacing: .compact)
                        .padding(.vertical, 40)

                    HStack {
                        Text(L10n.Nighthawk.SettingsTab.settings)
                            .paragraphMedium()
                        Spacer()
                    }

                    VStack {
                        settingRow(
                            title: L10n.Nighthawk.SettingsTab.notificationsTitle,
                            subtitle: L10n.Nighthawk.SettingsTab.notificationsSubtitle,
                            icon:  Asset.Assets.Icons.Nighthawk.notifications.image,
                            action: { viewStore.send(.goTo(.notifications())) }
                        )
                        
//                        settingRow(
//                            title: L10n.Nighthawk.SettingsTab.fiatTitle,
//                            subtitle: L10n.Nighthawk.SettingsTab.fiatSubtitle,
//                            icon: Asset.Assets.Icons.Nighthawk.fiat.image,
//                            action: { viewStore.send(.goTo(.fiat())) }
//                        )
                        
                        settingRow(
                            title: L10n.Nighthawk.SettingsTab.securityTitle,
                            subtitle: L10n.Nighthawk.SettingsTab.securitySubtitle,
                            icon: Asset.Assets.Icons.Nighthawk.security.image,
                            action: { viewStore.send(.goTo(.security())) }
                        )
                        
                        settingRow(
                            title: L10n.Nighthawk.SettingsTab.backupTitle,
                            subtitle: L10n.Nighthawk.SettingsTab.backupSubtitle,
                            icon: Asset.Assets.Icons.Nighthawk.backup.image,
                            action: { viewStore.send(.goTo(.backup())) }
                        )
                        
                        settingRow(
                            title: L10n.Nighthawk.SettingsTab.rescanTitle,
                            subtitle: L10n.Nighthawk.SettingsTab.rescanTitle,
                            icon: Asset.Assets.Icons.Nighthawk.rescan.image,
                            action: { viewStore.send(.goTo(.rescan())) }
                        )
                        
                        // TODO: [#1095] Hiding this until known for sure whether SDK changes are needed to support it.
                        // TODO: Open an issue in the iOS SDK repo if and when it is determined necessary. (the below is for Android)
                        // (https://github.com/zcash/zcash-android-wallet-sdk/issues/1095)
//                        settingRow(
//                            title: L10n.Nighthawk.SettingsTab.changeServerTitle,
//                            subtitle: L10n.Nighthawk.SettingsTab.changeServerSubtitle,
//                            icon: Asset.Assets.Icons.Nighthawk.server.image,
//                            action: { viewStore.send(.goTo(.changeServer())) }
//                        )
                        
                        settingRow(
                            title: L10n.Nighthawk.SettingsTab.externalServicesTitle,
                            subtitle: L10n.Nighthawk.SettingsTab.externalServicesSubtitle,
                            icon: Asset.Assets.Icons.Nighthawk.services.image,
                            action: { viewStore.send(.goTo(.externalServices())) }
                        )
                        
                        settingRow(
                            title: L10n.Nighthawk.SettingsTab.advancedTitle,
                            subtitle: L10n.Nighthawk.SettingsTab.advancedSubtitle,
                            icon:  Asset.Assets.Icons.Nighthawk.settings.image,
                            action: { viewStore.send(.goTo(.advanced())) }
                        )
                        
                        settingRow(
                            title: L10n.Nighthawk.SettingsTab.aboutTitle,
                            subtitle: L10n.Nighthawk.SettingsTab.aboutSubtitle(viewStore.appVersion),
                            icon: Asset.Assets.Icons.Nighthawk.about.image,
                            action: { viewStore.send(.goTo(.about())) }
                        )
                    }
                }
                .padding(.horizontal, 25)
                .onAppear { viewStore.send(.onAppear) }
            }
            .applyNighthawkBackground()
            .navigationBarTitle("")
        } destination: { state in
            switch state {
            case .notifications:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.notifications,
                    action: NHSettingsReducer.Path.Action.notifications,
                    then: NotificationsView.init(store:)
                )
            case .fiat:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.fiat,
                    action: NHSettingsReducer.Path.Action.fiat,
                    then: FiatView.init(store:)
                )
            case .security:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.security,
                    action: NHSettingsReducer.Path.Action.security,
                    then: SecurityView.init(store:)
                )
            case .backup:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.backup,
                    action: NHSettingsReducer.Path.Action.backup,
                    then: BackupView.init(store:)
                )
            case .rescan:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.rescan,
                    action: NHSettingsReducer.Path.Action.rescan,
                    then: RescanView.init(store:)
                )
            case .changeServer:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.changeServer,
                    action: NHSettingsReducer.Path.Action.changeServer,
                    then: ChangeServerView.init(store:)
                )
            case .externalServices:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.externalServices,
                    action: NHSettingsReducer.Path.Action.externalServices,
                    then: ExternalServicesView.init(store:)
                )
            case .advanced:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.advanced,
                    action: NHSettingsReducer.Path.Action.advanced,
                    then: AdvancedView.init(store:)
                )
            case .about:
                CaseLet(
                    state: /NHSettingsReducer.Path.State.about,
                    action: NHSettingsReducer.Path.Action.about,
                    then: AboutView.init(store:)
                )
            }
        }
    }
}

// MARK: - Subviews
private extension NHSettingsView {
    func notifications(with viewStore: NHSettingsViewStore) -> some View {
        settingRow(
            title: L10n.Nighthawk.SettingsTab.notificationsTitle,
            subtitle: L10n.Nighthawk.SettingsTab.notificationsSubtitle,
            icon: Asset.Assets.Icons.Nighthawk.notifications.image,
            action: { viewStore.send(.goTo(.notifications())) }
        )
    }
    
    func settingRow(
        title: String,
        subtitle: String,
        icon: Image,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack {
                HStack {
                    VStack {
                        HStack(alignment: .center, spacing: 14) {
                            icon
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.white)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(title)
                                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                                    .multilineTextAlignment(.leading)
                                
                                Text(subtitle)
                                    .caption()
                            }
                            .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
                
                Divider()
                    .frame(height: 2)
                    .overlay(Asset.Colors.Nighthawk.navy.color)
            }
        }
    }
}
