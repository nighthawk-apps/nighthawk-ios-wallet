//
//  TorNetworkView.swift
//  stealth
//
//  Tor network settings screen — matches Android's TorNetworkSettingsScreen.kt
//  Three sections: Routing, Built-in Tor (Arti), SOCKS endpoint.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct TorNetworkView: View {
    @Bindable var store: StoreOf<TorNetwork>
    @Environment(\.dismiss) private var dismiss
    
    public init(store: StoreOf<TorNetwork>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Top bar
                topBar
                
                // Intro (matches Android TorNetworkSettingsIntro)
                introSection
                
                // Section 1: App-wide Tor routing
                torRoutingSection
                
                sectionDivider
                
                // Section 2: Built-in Tor (Arti)
                builtInTorSection
                
                sectionDivider
                
                // Section 3: SOCKS endpoint
                socksEndpointSection
                
                // Footer + Done
                footerSection
            }
        }
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }
}

// MARK: - Top Bar
private extension TorNetworkView {
    var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Intro
private extension TorNetworkView {
    var introSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tor network")
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 22))
                .foregroundColor(.white)
            
            Text("Tor is off by default — the app uses your normal mobile network (clearnet). Turn on app-wide Tor routing only if you want wallet HTTP and DarkIRC P2P to use SOCKS (default loopback 127.0.0.1:9050). You can use built-in Arti or an external SOCKS proxy.")
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}

// MARK: - Section 1: App-wide Tor routing
private extension TorNetworkView {
    var torRoutingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("App-wide Tor routing")
            
            Text("Routes wallet HTTPS, embedded darkfid/darkirc P2P (onion seeds), and remote IRC hosts through SOCKS. Loopback embedded DarkIRC IRC stays direct.")
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer().frame(height: 8)
            
            // Wallet toggle
            torSwitchRow(
                title: "Route wallet + chat P2P through Tor SOCKS",
                isOn: Binding(
                    get: { store.torForWallet },
                    set: { store.send(.torForWalletToggled($0)) }
                )
            )
            
            // Arti status indicator (when enabled)
            if store.isTorEnabled {
                HStack(spacing: 8) {
                    Circle()
                        .fill(artiStatusColor)
                        .frame(width: 10, height: 10)
                    
                    Text(store.artiStatus.rawValue)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    if store.artiStatus == .bootstrapping {
                        ProgressView(value: store.artiBootstrapProgress)
                            .tint(Asset.Colors.Nighthawk.peach.color)
                            .frame(width: 60)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
    
    var artiStatusColor: Color {
        switch store.artiStatus {
        case .connected: return .green
        case .bootstrapping: return .yellow
        case .stopped: return .gray
        case .failed: return .red
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
            .foregroundColor(.white)
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
                .foregroundColor(enabled ? .white : .white.opacity(0.4))
            
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
                .foregroundColor(enabled ? .white : .white.opacity(0.4))
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
