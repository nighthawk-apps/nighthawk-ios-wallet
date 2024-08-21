//
//  NighthawkSettingsView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import Generated
import RecoveryPhraseDisplay
import SwiftUI
import UIComponents

struct NighthawkSettingsView: View {
    private enum Constants {
        static let faceId = "Face ID"
        static let touchId = "Touch ID"
    }
    
    @Bindable var store: StoreOf<NighthawkSettings>
    
    var body: some View {
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
                    action: { store.send(.rowTapped(.notifications)) }
                )
                
                settingRow(
                    title: L10n.Nighthawk.SettingsTab.fiatTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.fiatSubtitle,
                    icon:  Asset.Assets.Icons.Nighthawk.fiat.image,
                    action: { store.send(.rowTapped(.fiat)) }
                )
                
                if store.biometryType != .none {
                    settingRow(
                        title: L10n.Nighthawk.SettingsTab.securityTitle,
                        subtitle: L10n.Nighthawk.SettingsTab.securitySubtitle(
                            store.biometryType == .faceID
                            ? Constants.faceId
                            : Constants.touchId
                        ),
                        icon: Asset.Assets.Icons.Nighthawk.security.image,
                        action: { store.send(.rowTapped(.security)) }
                    )
                }
                
                settingRow(
                    title: L10n.Nighthawk.SettingsTab.backupTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.backupSubtitle,
                    icon: Asset.Assets.Icons.Nighthawk.backup.image,
                    action: { store.send(.rowTapped(.backup)) }
                )
                
                settingRow(
                    title: L10n.Nighthawk.SettingsTab.rescanTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.rescanSubtitle,
                    icon: Asset.Assets.Icons.Nighthawk.rescan.image,
                    action: { store.send(.rescanTapped) }
                )
                
                settingRow(
                    title: L10n.Nighthawk.SettingsTab.changeServerTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.changeServerSubtitle,
                    icon: Asset.Assets.Icons.Nighthawk.server.image,
                    action: { store.send(.rowTapped(.changeServer)) }
                )
                
                // TODO: Enable once we can actually test this.
//                    settingRow(
//                        title: L10n.Nighthawk.SettingsTab.externalServicesTitle,
//                        subtitle: L10n.Nighthawk.SettingsTab.externalServicesSubtitle,
//                        icon: Asset.Assets.Icons.Nighthawk.services.image,
//                        action: { viewStore.send(.rowTapped(.externalServices)) }
//                    )
                
                settingRow(
                    title: L10n.Nighthawk.SettingsTab.advancedTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.advancedSubtitle,
                    icon:  Asset.Assets.Icons.Nighthawk.settings.image,
                    action: { store.send(.rowTapped(.advanced)) }
                )
                
                settingRow(
                    title: L10n.Nighthawk.SettingsTab.aboutTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.aboutSubtitle(store.appVersion),
                    icon: Asset.Assets.Icons.Nighthawk.about.image,
                    action: { store.send(.rowTapped(.about))}
                )
            }
        }
        .padding(.horizontal, 25)
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
}

// MARK: - Subviews
private extension NighthawkSettingsView {
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
