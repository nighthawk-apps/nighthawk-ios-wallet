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
            Text("Wallet, chat, and node traffic go over the Nym mixnet by default, which hides your IP address from servers. Chat reaches the public DarkIRC seeds through that same tunnel. Onion-only peers need Tor. The first connection usually takes a few seconds and can take up to a minute.")
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

// MARK: - Section 0: Wallet network
private extension TorNetworkView {
    var walletNetworkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Wallet network")

            Text("Used for lightwalletd sync and transaction broadcast. Changing it reconnects the wallet.")
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 4)

            ForEach(NighthawkSetting.PrivacyNetwork.allCases) { network in
                privacyNetworkRow(network)
            }

            if store.isNymEnabled {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor(store.nymStatus))
                        .frame(width: 10, height: 10)

                    Text("Nym: \(store.nymStatus.rawValue)")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

                    if store.nymStatus == .failed || store.nymStatus == .stopped {
                        Button("Retry") { store.send(.startNym) }
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }

    func privacyNetworkRow(_ network: NighthawkSetting.PrivacyNetwork) -> some View {
        let selected = store.privacyNetwork == network
        return Button(action: { store.send(.privacyNetworkSelected(network)) }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selected ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.parmaviolet.color)

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
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    func statusColor(_ status: TorNetwork.State.ArtiStatus) -> Color {
        switch status {
        case .connected: return .green
        case .bootstrapping: return .yellow
        case .stopped: return .gray
        case .failed: return .red
        }
    }
}

private extension NighthawkSetting.PrivacyNetwork {
    var title: String {
        switch self {
        case .nym: return "Nym mixnet (recommended)"
        case .tor: return "Tor"
        case .direct: return "Direct"
        }
    }

    var subtitle: String {
        switch self {
        case .nym: return "Mixes packets across five hops. Chat uses the clearnet seeds through the mixnet. Cannot reach .onion addresses."
        case .tor: return "Onion routing through built-in Arti or the SOCKS endpoint below."
        case .direct: return "Connects straight to the server. It sees your IP address."
        }
    }
}

// MARK: - Section 2: Built-in Tor (Arti)
private extension TorNetworkView {
    var builtInTorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Built-in Tor (Arti)")

            Text("Runs Arti (Rust Tor) inside the app and exposes a loopback SOCKS listener. This is separate from an external Tor/SOCKS app you configure below.")
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 8)

            // Embedded Arti toggle
            VStack(alignment: .leading, spacing: 4) {
                torSwitchRow(
                    title: "Use built-in Arti",
                    isOn: Binding(
                        get: { store.torMode == .embeddedArti },
                        set: { store.send(.torModeChanged($0 ? .embeddedArti : .externalSocks)) }
                    ),
                    enabled: store.isTorEnabled
                )

                if !store.isTorEnabled {
                    Text("Enable app-wide Tor routing above to use built-in Arti.")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.7))
                        .padding(.leading, 4)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Section 3: SOCKS endpoint
private extension TorNetworkView {
    var socksEndpointSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("SOCKS endpoint")

            Text(store.socksDescription)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 8)

            // SOCKS host
            socksField(
                label: "SOCKS host",
                text: $store.externalSocksAddress,
                placeholder: "127.0.0.1",
                enabled: store.isTorEnabled,
                keyboardType: .default
            )

            Spacer().frame(height: 8)

            // SOCKS port
            socksField(
                label: "SOCKS port",
                text: $store.externalSocksPort,
                placeholder: "9050",
                enabled: store.isTorEnabled,
                keyboardType: .numberPad
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Footer
private extension TorNetworkView {
    var footerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer().frame(height: 16)

            Text("Changing built-in Tor or SOCKS restarts embedded DarkIRC when enabled so P2P/event-graph transport matches. Open Chat to verify green status lights.")
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 12)

            Button(action: { store.send(.doneTapped) }) {
                Text("Done")
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
            }
            .buttonStyle(.nighthawkPrimary())
        }
        .padding(.horizontal)
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
                .overlay(Asset.Colors.Nighthawk.navy.color.opacity(0.5))
            Spacer().frame(height: 16)
        }
        .padding(.horizontal)
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
