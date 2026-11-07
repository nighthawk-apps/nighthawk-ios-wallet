//
//  AdvancedView.swift
//
//
//  Created by Matthew Watt on 8/3/23.
//

import AlertToast
import ComposableArchitecture
import Generated
import Models
import DarkfiCore
import SDKSynchronizer
import SwiftUI
import UIComponents

public struct AdvancedView: View {
    @Bindable var store: StoreOf<Advanced>
    @ObservedObject private var mesh = NighthawkMeshController.shared

    public init(store: StoreOf<Advanced>) {
        self.store = store
    }

    public var body: some View {
        ScrollView([.vertical], showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.SettingsTab.Advanced.ScreenMode.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

                Text(L10n.Nighthawk.SettingsTab.Advanced.ScreenMode.subtitle)
                    .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)

                RadioSelectionList(
                    options: NighthawkSetting.ScreenMode.allCases,
                    selection: $store.selectedScreenMode
                ) { option in
                    HStack {
                        switch option {
                        case .keepOn:
                            Text(L10n.Nighthawk.SettingsTab.Advanced.ScreenMode.keepOn)
                                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                        case .off:
                            Text(L10n.Nighthawk.SettingsTab.Advanced.ScreenMode.off)
                                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 12)
                }

                Text("Nearby mesh")
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

                Text("Relay DarkIRC with nearby Nighthawk phones over Bluetooth. Share-internet stays off.")
                    .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)

                Toggle(isOn: Binding(
                    get: { mesh.enabled },
                    set: { mesh.setEnabled($0) }
                )) {
                    Text("Nearby mesh")
                        .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                }
                .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.Nighthawk.peach.color))

                Text(mesh.statusLine)
                    .paragraphMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(3)

                banditSettings

                Text(L10n.Nighthawk.SettingsTab.Advanced.NukeLocalDatabases.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

                Text(L10n.Nighthawk.SettingsTab.Advanced.NukeLocalDatabases.subtitle)
                    .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)

                Button(L10n.Nighthawk.SettingsTab.Advanced.NukeLocalDatabases.title) {
                    store.send(.nukeLocalDatabasesTapped)
                }
                .buttonStyle(
                    .nighthawkPrimary(
                        backgroundColor: StealthTheme.Colors.statusDanger,
                        foregroundColor: StealthTheme.Colors.onDanger
                    )
                )

                Text(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

                Text(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.subtitle)
                    .paragraphBold(color: StealthTheme.Colors.statusDanger)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)

                Button(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.title) {
                    store.send(.deleteWalletTapped)
                }
                .buttonStyle(
                    .nighthawkPrimary(
                        backgroundColor: StealthTheme.Colors.statusDanger,
                        foregroundColor: StealthTheme.Colors.onDanger
                    )
                )
            }
            .padding(.top, 8)
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 25)
        .applyNighthawkBackground()
        .onAppear { store.send(.onAppear) }
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
}

// MARK: - Subviews
private extension AdvancedView {
    @MainActor
    @ViewBuilder
    var banditSettings: some View {
        if store.showBanditSettings {
            if store.supportsAlternateIcons {
                Text(L10n.Nighthawk.SettingsTab.Advanced.AppIcon.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

                RadioSelectionList(
                    options: NighthawkSetting.AppIcon.allCases,
                    selection: $store.selectedAppIcon
                ) { option in
                    HStack(alignment: .center) {
                        option.preview
                            .resizable().scaledToFit()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.tertiary, lineWidth: 2)
                            )

                        Text(option.label)
                            .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)

                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }

            Toggle(isOn: Binding(
                get: { WalletSyncPrivacy.strictOmrOnly },
                set: { WalletSyncPrivacy.setStrictOmrOnly($0) }
            )) {
                Text("Experimental UnifOMR")
                    .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
            }
            .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.Nighthawk.peach.color))
            .padding(.vertical, 8)
            Text("Off is the default. Trial decryption finds every payment, including ones from Dark Wallet or another server. On is experimental: both wallets must register on this same lightwalletd first, or funds can stay invisible. It also uploads a large detection key.")
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                .padding(.bottom, 8)

            Text(L10n.Nighthawk.SettingsTab.Advanced.Theme.title)
                .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

            RadioSelectionList(
                options: NighthawkSetting.Theme.allCases,
                selection: $store.theme
            ) { option in
                HStack {
                    switch option {
                    case .`default`, .cyberpunk:
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.Nighthawk.SettingsTab.Advanced.Theme.cyberpunk)
                                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                            Text(L10n.Nighthawk.SettingsTab.Advanced.Theme.cyberpunkDetail)
                                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                        }
                    case .dark:
                        Text(L10n.Nighthawk.SettingsTab.Advanced.Theme.dark)
                            .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    case .paper:
                        Text(L10n.Nighthawk.SettingsTab.Advanced.Theme.paper)
                            .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    }

                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
    }
}
