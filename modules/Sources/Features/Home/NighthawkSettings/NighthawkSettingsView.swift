//
//  NighthawkSettingsView.swift
//  stealth
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
        NighthawkSplitContainer {
            settingsColumn
        } secondary: {
            settingsCompanionPane
        }
        .onAppear { store.send(.onAppear) }
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }

    private var settingsColumn: some View {
        ScrollView([.vertical], showsIndicators: false) {
            HStack {
                Text(L10n.Nighthawk.SettingsTab.settings.uppercased())
                    .title(color: Asset.Colors.Nighthawk.textHeader.color)
                Spacer()
            }
            .padding(.top, NighthawkLayout.wallpaperWordmarkClearance)
            .padding(.bottom, 13)

            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.steelBorder.color)

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.notificationsTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.notificationsSubtitle,
                    icon: Asset.Assets.Icons.Nighthawk.notifications.image,
                    action: { store.send(.rowTapped(.notifications)) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.fiatTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.fiatSubtitle,
                    icon: Asset.Assets.Icons.Nighthawk.fiat.image,
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

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.chatSettingsTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.chatSettingsSubtitle,
                    icon: Image(systemName: "bubble.left.and.bubble.right"),
                    action: { store.send(.rowTapped(.chatSettings)) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.networkPrivacyTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.networkPrivacySubtitle,
                    icon: Image(systemName: "network"),
                    action: { store.send(.rowTapped(.torNetwork)) }
                )

                settingRow(
                    title: L10n.Nighthawk.DaoHub.title,
                    subtitle: L10n.Nighthawk.DaoHub.browseDescription,
                    icon: Image(systemName: "person.3"),
                    action: { store.send(.rowTapped(.daoHub)) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.advancedTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.advancedSubtitle,
                    icon: Asset.Assets.Icons.Nighthawk.settings.image,
                    action: { store.send(.rowTapped(.advanced)) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.aboutTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.aboutSubtitle(store.appVersion),
                    icon: Asset.Assets.Icons.Nighthawk.about.image,
                    action: { store.send(.rowTapped(.about)) }
                )
            }
        }
        .padding(.horizontal, 25)
        .applyNighthawkBackground()
    }

    private var settingsCompanionPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.SettingsTab.settings.uppercased())
                    .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                Text(L10n.Nighthawk.SettingsTab.selectSettingPrompt)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                Text(L10n.Nighthawk.SettingsTab.aboutSubtitle(store.appVersion))
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .applyNighthawkBackground()
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
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    icon
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                        .frame(width: 24, height: 24, alignment: .center)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                            .multilineTextAlignment(.leading)

                        Text(subtitle)
                            .caption()
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 14)
                .frame(minHeight: 56)
                .contentShape(Rectangle())

                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.steelBorder.color)
            }
        }
        .buttonStyle(.plain)
    }
}
