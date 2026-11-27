//
//  TorNetworkView.swift
//  stealth
//
//  Tor network settings screen — matches Android's TorNetworkSettingsScreen.kt
//  Three sections: Routing, Built-in Tor (Arti), SOCKS endpoint.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct TorNetworkView: View {
    @Bindable var store: StoreOf<TorNetwork>

    public init(store: StoreOf<TorNetwork>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Intro (matches Android TorNetworkSettingsIntro)
                introSection

                // Section 0: Wallet network (Nym / Tor / Direct)
                walletNetworkSection

                if store.privacyNetwork == .tor {
                    sectionDivider
                    builtInTorSection
                    sectionDivider
                    socksEndpointSection
                }

                // Footer + Done
                footerSection
            }
        }
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }
}

// MARK: - Intro
private extension TorNetworkView {
    var introSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Nighthawk.SettingsTab.TorNetwork.intro)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 25)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

// MARK: - Section 0: Wallet network
private extension TorNetworkView {
    var walletNetworkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading(L10n.Nighthawk.SettingsTab.TorNetwork.walletNetworkTitle)

            Text(L10n.Nighthawk.SettingsTab.TorNetwork.walletNetworkSubtitle)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 4)

            VStack(spacing: 0) {
                ForEach(
                    NighthawkSetting.PrivacyNetwork.allCases.filter {
                        !(store.disableDirectConnection && $0 == .direct)
                    }
                ) { network in
                    privacyNetworkRow(network)
                }
            }

            if store.disableDirectConnection {
                Text("Direct (clearnet) connections are permanently disabled in Settings → Advanced.")
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }

            if store.isNymEnabled {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor(store.nymStatus))
                        .frame(width: 10, height: 10)

                    Text(L10n.Nighthawk.SettingsTab.TorNetwork.nymStatus(store.nymStatus.rawValue))
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

                    if store.nymStatus == .failed || store.nymStatus == .stopped {
                        Button(L10n.Nighthawk.Chat.retry) { store.send(.startNym) }
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 25)
    }

    func privacyNetworkRow(_ network: NighthawkSetting.PrivacyNetwork) -> some View {
        let selected = store.privacyNetwork == network
        return Button(action: { store.send(.privacyNetworkSelected(network)) }) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selected ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.parmaviolet.color)
                    .frame(width: 24, height: 24, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(network.title)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 15))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    Text(network.subtitle)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.vertical, 10)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    func statusColor(_ status: TorNetwork.State.ArtiStatus) -> Color {
        switch status {
        case .connected: return StealthTheme.Colors.statusSuccess
        case .bootstrapping: return StealthTheme.Colors.statusWarning
        case .stopped: return Asset.Colors.Nighthawk.parmaviolet.color
        case .failed: return StealthTheme.Colors.statusDanger
        }
    }
}

private extension NighthawkSetting.PrivacyNetwork {
    var title: String {
        switch self {
        case .nym: return L10n.Nighthawk.SettingsTab.TorNetwork.nymTitle
        case .tor: return L10n.Nighthawk.SettingsTab.TorNetwork.torTitle
        case .direct: return L10n.Nighthawk.SettingsTab.TorNetwork.directTitle
        }
    }

    var subtitle: String {
        switch self {
        case .nym: return L10n.Nighthawk.SettingsTab.TorNetwork.nymSubtitle
        case .tor: return L10n.Nighthawk.SettingsTab.TorNetwork.torSubtitle
        case .direct: return L10n.Nighthawk.SettingsTab.TorNetwork.directSubtitle
        }
    }
}

// MARK: - Section 2: Built-in Tor (Arti)
private extension TorNetworkView {
    var builtInTorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading(L10n.Nighthawk.SettingsTab.TorNetwork.builtInTorTitle)

            Text(L10n.Nighthawk.SettingsTab.TorNetwork.builtInTorSubtitle)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 8)

            // Embedded Arti toggle
            VStack(alignment: .leading, spacing: 4) {
                torSwitchRow(
                    title: L10n.Nighthawk.SettingsTab.TorNetwork.useBuiltInArti,
                    isOn: Binding(
                        get: { store.torMode == .embeddedArti },
                        set: { store.send(.torModeChanged($0 ? .embeddedArti : .externalSocks)) }
                    ),
                    enabled: store.isTorEnabled
                )

                if !store.isTorEnabled {
                    Text(L10n.Nighthawk.SettingsTab.TorNetwork.enableTorHint)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.7))
                        .padding(.leading, 4)
                }
            }
        }
        .padding(.horizontal, 25)
    }
}

// MARK: - Section 3: SOCKS endpoint
private extension TorNetworkView {
    var socksEndpointSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading(L10n.Nighthawk.SettingsTab.TorNetwork.socksEndpointTitle)

            Text(store.socksDescription)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 8)

            // SOCKS host
            socksField(
                label: L10n.Nighthawk.SettingsTab.TorNetwork.socksHost,
                text: $store.externalSocksAddress,
                placeholder: "127.0.0.1",
                enabled: store.isTorEnabled,
                keyboardType: .default
            )

            Spacer().frame(height: 8)

            // SOCKS port
            socksField(
                label: L10n.Nighthawk.SettingsTab.TorNetwork.socksPort,
                text: $store.externalSocksPort,
                placeholder: "9050",
                enabled: store.isTorEnabled,
                keyboardType: .numberPad
            )
        }
        .padding(.horizontal, 25)
    }
}

// MARK: - Footer
private extension TorNetworkView {
    var footerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer().frame(height: 16)

            Text(L10n.Nighthawk.SettingsTab.TorNetwork.footer)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 12)

            Button(action: { store.send(.doneTapped) }) {
                Text(L10n.General.done)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
            }
            .buttonStyle(.nighthawkPrimary())
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 24)
    }
}

// MARK: - Reusable components
private extension TorNetworkView {
    func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.custom(FontFamily.PulpDisplay.bold.name, size: 15))
            .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
    }

    var sectionDivider: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)
            Divider()
                .frame(height: 1)
                .overlay(Asset.Colors.Nighthawk.steelBorder.color)
            Spacer().frame(height: 16)
        }
        .padding(.horizontal, 25)
    }

    func torSwitchRow(title: String, isOn: Binding<Bool>, enabled: Bool = true) -> some View {
        HStack {
            Text(title)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 15))
                .foregroundColor(enabled ? Asset.Colors.Nighthawk.textHeader.color : Asset.Colors.Nighthawk.textHeader.color.opacity(0.4))

            Spacer()

            Toggle("", isOn: isOn)
                .tint(Asset.Colors.Nighthawk.peach.color)
                .labelsHidden()
                .disabled(!enabled)
        }
        .padding(.vertical, 4)
    }

    func socksField(
        label: String,
        text: Binding<String>,
        placeholder: String,
        enabled: Bool,
        keyboardType: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

            TextField(placeholder, text: text)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 15))
                .foregroundColor(enabled ? Asset.Colors.Nighthawk.textHeader.color : Asset.Colors.Nighthawk.textHeader.color.opacity(0.4))
                .keyboardType(keyboardType)
                .disabled(!enabled)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Asset.Colors.Nighthawk.navy.color.opacity(enabled ? 1.0 : 0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            Asset.Colors.Nighthawk.parmaviolet.color.opacity(enabled ? 0.3 : 0.1),
                            lineWidth: 1
                        )
                )
        }
    }
}
