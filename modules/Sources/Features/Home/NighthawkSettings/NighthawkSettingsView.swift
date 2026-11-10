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
    @Environment(\.nighthawkUsesCompanionPane) private var usesCompanionPane
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
                    action: { open(.notifications) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.fiatTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.fiatSubtitle,
                    icon: Asset.Assets.Icons.Nighthawk.fiat.image,
                    action: { open(.fiat) }
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
                        action: { open(.security) }
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
                    action: { open(.changeServer) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.chatSettingsTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.chatSettingsSubtitle,
                    icon: Image(systemName: "bubble.left.and.bubble.right"),
                    action: { open(.chatSettings) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.networkPrivacyTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.networkPrivacySubtitle,
                    icon: Image(systemName: "network"),
                    action: { open(.torNetwork) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.advancedTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.advancedSubtitle,
                    icon: Asset.Assets.Icons.Nighthawk.settings.image,
                    action: { open(.advanced) }
                )

                settingRow(
                    title: L10n.Nighthawk.SettingsTab.aboutTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.aboutSubtitle(store.appVersion),
                    icon: Asset.Assets.Icons.Nighthawk.about.image,
                    action: { open(.about) }
                )
            }
        }
        .padding(.horizontal, 25)
        .applyNighthawkBackground()
    }

    private func open(_ screen: NighthawkSettings.State.Screen) {
        if usesCompanionPane {
            store.send(.foldRowTapped(screen))
        } else {
            store.send(.rowTapped(screen))
        }
    }

    private var settingsCompanionPane: some View {
        VStack(spacing: 0) {
            if store.foldDetail != nil {
                HStack {
                    Button("Close") { store.send(.foldClosed) }
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            foldDetail
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var foldDetail: some View {
        if let store = store.scope(state: \.foldDetail?.about, action: \.foldDetail.about) {
            AboutView(store: store)
        } else if let store = store.scope(state: \.foldDetail?.advanced, action: \.foldDetail.advanced) {
            AdvancedView(store: store)
        } else if let store = store.scope(state: \.foldDetail?.changeServer, action: \.foldDetail.changeServer) {
            ChangeServerView(store: store)
        } else if let store = store.scope(state: \.foldDetail?.chatSettings, action: \.foldDetail.chatSettings) {
            ChatSettingsView(store: store)
        } else if let store = store.scope(state: \.foldDetail?.fiat, action: \.foldDetail.fiat) {
            FiatView(store: store)
        } else if let store = store.scope(state: \.foldDetail?.notifications, action: \.foldDetail.notifications) {
            NotificationsView(store: store)
        } else if let store = store.scope(state: \.foldDetail?.security, action: \.foldDetail.security) {
            SecurityView(store: store)
        } else if let store = store.scope(state: \.foldDetail?.torNetwork, action: \.foldDetail.torNetwork) {
            TorNetworkView(store: store)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Nighthawk.SettingsTab.settings.uppercased())
                        .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    Text("Select a setting on the left to open it here.")
                        .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    Text(L10n.Nighthawk.SettingsTab.aboutSubtitle(store.appVersion))
                        .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .applyNighthawkBackground()
        }
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
