//
//  ChatView.swift
//  stealth
//
//  DarkFi IRC chat view.
//  Displays channels, messages, and a compose bar.
//

import ComposableArchitecture
import DarkfiCore
import Generated
import Models
import SwiftUI
import UIComponents
import UIKit

struct ChatView: View {
    @Bindable var store: StoreOf<Chat>
    @Environment(\.scenePhase) var scenePhase
    @State var showPeers = false
    @State var clearnetURL: String?
    @State var showPaySheet = false
    @State var payAmount = ""
    @State var payMemo = ""
    @State var payAddress = ""
    @ObservedObject var themes = NighthawkThemeController.shared
    @ObservedObject var mesh = NighthawkMeshController.shared

    var body: some View {
        VStack(spacing: 0) {
            inboxBar
            if let notice = store.fudNotice {
                Text(notice)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Asset.Colors.Nighthawk.navy.color)
                    .onTapGesture { store.send(.dismissFudNotice) }
            }

            if store.connectionState == .disconnected || store.connectionState == .error,
               store.messages.isEmpty && store.channelMessages.isEmpty {
                disconnectedView
            } else {
                connectedView
            }
        }
        .alert(L10n.Nighthawk.Chat.clearnetAlertTitle, isPresented: Binding(
            get: { clearnetURL != nil },
            set: { if !$0 { clearnetURL = nil } }
        )) {
            Button(L10n.Nighthawk.Chat.clearnetOpenBrowser) {
                if let clearnetURL, let url = URL(string: clearnetURL) {
                    UIApplication.shared.open(url)
                }
                clearnetURL = nil
            }
            Button(L10n.Nighthawk.Chat.clearnetCopyLink) {
                if let clearnetURL {
                    UIPasteboard.general.setItems(
                        [[UIPasteboard.typeAutomatic: clearnetURL]],
                        options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(60)]
                    )
                }
                clearnetURL = nil
            }
            Button(L10n.General.cancel, role: .cancel) { clearnetURL = nil }
        } message: {
            Text(L10n.Nighthawk.Chat.clearnetAlertMessage)
        }
        .sheet(isPresented: $showPaySheet) {
            paySheet
        }
        // Clears the wallpaper NIGHTHAWK wordmark under the status bar.
        .padding(.top, NighthawkLayout.wallpaperWordmarkClearance)
        .onAppear { store.send(.onAppear) }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Connection Status Bar (matches Android ChatStatusRow)
extension ChatView {
    /// Theme-aware selection container & accent (magenta in Cyberpunk, slate in Stealth, neutral in Paper).
    var chatSelectionPink: Color { themes.theme.secondaryContainerColor }
    var chatSelectionPinkBright: Color { themes.theme.secondaryAccentColor }
    var chatSelectionOnPink: Color { themes.theme.onSecondaryContainerColor }

    var chatBackdrop: Color {
        themes.theme.usesCyberpunkChrome
            ? Color.black.opacity(0.45)
            : Asset.Colors.Nighthawk.darkNavy.color
    }

    var privacyRouteLabel: String {
        switch store.connectionState {
        case .connectedViaNym: return L10n.Nighthawk.Chat.routeNym
        case .connectedViaTor: return L10n.Nighthawk.Chat.routeTor
        case .connectedDirect: return L10n.Nighthawk.Chat.routeDirect
        case .connecting, .startingDaemon, .waitingForDagSync: return L10n.Nighthawk.Chat.routeBootstrapping
        case .degraded: return L10n.Nighthawk.Chat.routeDegraded
        case .disconnected, .error: return L10n.Nighthawk.Chat.routeOffline
        }
    }

    var inboxBar: some View {
        HStack(spacing: 8) {
            ForEach(Chat.State.ChatTab.allCases, id: \.self) { tab in
                Button(action: { store.send(.tabSelected(tab)) }) {
                    Text(tab.rawValue)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                        .foregroundColor(store.selectedTab == tab ? chatSelectionOnPink : Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .padding(.vertical, 8)
                        .background(
                            store.selectedTab == tab
                                ? chatSelectionPink.opacity(themes.theme.usesCyberpunkChrome ? 0.38 : 1.0)
                                : Color.clear
                        )
                        .contentShape(Rectangle())
                }
            }
            Spacer(minLength: 0)
            // Equal-pitch trailing actions (matches Android chat chrome).
            HStack(spacing: 0) {
                chatChromeIconButton(
                    systemName: "plus",
                    label: L10n.Nighthawk.Chat.newDm
                ) {
                    store.send(.newDmTapped)
                }
                chatChromeIconButton(
                    systemName: "doc.text",
                    label: L10n.Nighthawk.Chat.request
                ) {
                    store.send(.requestMoneyTapped)
                }
                chatChromeIconButton(
                    systemName: "info.circle",
                    label: L10n.Nighthawk.Chat.peers
                ) {
                    showPeers = true
                }
                chatChromeIconButton(
                    systemName: "gearshape",
                    label: L10n.Nighthawk.Chat.settings
                ) {
                    store.send(.settingsTapped)
                }
            }
        }
        .padding(.trailing, 4)
        .background(Asset.Colors.Nighthawk.navy.color.opacity(0.55))
        .sheet(isPresented: $showPeers) {
            connectionInfoSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func chatChromeIconButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(chatSelectionPinkBright)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    var connectionInfoSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Nighthawk.Chat.activePrivacyRoute)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                Text(privacyRouteLabel)
                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                connectionStatusBody
                Text(L10n.Nighthawk.SettingsTab.Advanced.Mesh.title)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .padding(.top, 8)
                Text(mesh.statusLine)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(4)
                Text(
                    store.chainTip > 0
                        ? L10n.Nighthawk.Chat.lightwalletdHeight(store.chainTip)
                        : L10n.Nighthawk.Chat.lightwalletdHeightUnavailable
                )
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                if let lwdMessage = store.lightStatusMessage, !lwdMessage.isEmpty {
                    let isStale = lwdMessage.lowercased().contains("not reached darkfid")
                        || lwdMessage.lowercased().contains("stale")
                        || lwdMessage.lowercased().contains("unreachable")
                    Text(lwdMessage)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(
                            isStale
                                ? StealthTheme.Colors.statusWarning
                                : Asset.Colors.Nighthawk.parmaviolet.color
                        )
                }
                if let snap = transportSnapshotSummary {
                    Text(L10n.Nighthawk.Chat.transportSummary(snap))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                }
                Text(
                    store.selectedTab == .direct
                        ? L10n.Nighthawk.Chat.directE2eBadge
                        : L10n.Nighthawk.Chat.publicPlaintextBadge
                )
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                Text(L10n.Nighthawk.Chat.outboundPeers)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .padding(.top, 8)
                ForEach(peerSlots, id: \.index) { slot in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(slot.connected ? StealthTheme.Colors.statusSuccess : Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.5))
                            .frame(width: 8, height: 8)
                        Text("\(slot.index)")
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        Text(slot.label)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(slot.connected ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.parmaviolet.color)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(chatBackdrop)
    }

    var connectionStatusBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            if store.embeddedNodeStatus != .notUsed {
                HStack(spacing: 8) {
                    statusDot(for: store.embeddedNodeStatus)
                    Text(L10n.Nighthawk.Chat.nodeStatus(store.embeddedNodeStatus.label))
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            HStack(spacing: 8) {
                connectionDot
                Text(L10n.Nighthawk.Chat.ircStatus(store.connectionState.label))
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Text(store.nickname)
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    .lineLimit(1)

                if store.connectionState == .error || store.connectionState == .disconnected {
                    Button(action: { store.send(.retryTapped) }) {
                        Text(L10n.Nighthawk.Chat.retry)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 12))
                            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
            }

            Text("\(store.privacyNetwork.chatLabel) · \(store.connectionState.label)")
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.tail)

            if let progress = store.dagSyncProgress,
               store.connectionState == .startingDaemon
                || store.connectionState == .connecting
                || store.connectionState == .waitingForDagSync {
                Text(progress)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            if let detail = store.diagnosticDetail {
                let lines = detail
                    .split(whereSeparator: \.isNewline)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .prefix(5)
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                        .foregroundColor(
                            store.connectionState == .error
                                ? StealthTheme.Colors.statusDanger
                                : Asset.Colors.Nighthawk.parmaviolet.color
                        )
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
    }

    private struct OutboundSlotPayload: Decodable {
        let slot: Int
        let url: String?
        let state: String
    }

    private struct TransportSnapshotPayload: Decodable {
        let kind: String
        let phase: String
        let mesh: Bool
        let sessionDirect: Bool
        let socksPort: UInt16?
    }

    var transportSnapshotSummary: String? {
        let raw = transportSnapshotJson()
        guard let data = raw.data(using: .utf8),
              let snap = try? JSONDecoder().decode(TransportSnapshotPayload.self, from: data) else {
            return nil
        }
        let port = snap.socksPort.map { " · :\($0)" } ?? ""
        let direct = snap.sessionDirect ? " · sessionDirect" : ""
        let mesh = snap.mesh ? " · mesh" : ""
        return "\(snap.kind) (\(snap.phase))\(port)\(direct)\(mesh)"
    }

    struct PeerSlot {
        let index: Int
        let label: String
        let connected: Bool
    }

    var peerSlots: [PeerSlot] {
        let raw = darkircOutboundSlots()
        if let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([OutboundSlotPayload].self, from: data),
           !decoded.isEmpty {
            return decoded.map { item in
                let label = item.url.map { "\(item.state) · \($0)" } ?? item.state
                return PeerSlot(index: item.slot, label: label, connected: item.state == "connected")
            }
        }
        return (0..<3).map { PeerSlot(index: $0, label: "unavailable", connected: false) }
    }

    var connectionDot: some View {
        Circle()
            .fill(connectionColor)
            .frame(width: 8, height: 8)
    }

    var connectionColor: Color {
        switch store.connectionState {
        case .connectedDirect, .connectedViaTor, .connectedViaNym: return StealthTheme.Colors.statusSuccess
        case .connecting, .startingDaemon, .waitingForDagSync, .degraded: return StealthTheme.Colors.statusWarning
        case .disconnected, .error: return StealthTheme.Colors.statusDanger
        }
    }

    func statusDot(for status: Chat.State.EmbeddedNodeStatus) -> some View {
        Circle()
            .fill(embeddedNodeColor(for: status))
            .frame(width: 8, height: 8)
    }

    func embeddedNodeColor(for status: Chat.State.EmbeddedNodeStatus) -> Color {
        switch status {
        case .running, .ready: return StealthTheme.Colors.statusSuccess
        case .starting, .waitingForPeers, .syncingDag: return StealthTheme.Colors.statusWarning
        case .notUsed: return Asset.Colors.Nighthawk.parmaviolet.color
        case .missingBinary, .failed: return StealthTheme.Colors.statusDanger
        }
    }
}

// MARK: - Disconnected State
extension ChatView {
    var disconnectedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Asset.Colors.Nighthawk.peach.color,
                            Asset.Colors.Nighthawk.parmaviolet.color
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 8)

            Text(L10n.Nighthawk.Chat.title)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 28))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

            Text(L10n.Nighthawk.Chat.subtitle)
                .multilineTextAlignment(.center)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .padding(.horizontal, 40)

            Button(action: { store.send(.connectTapped) }) {
                Text(L10n.Nighthawk.Chat.connect)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
            }
            .buttonStyle(.nighthawkPrimary(width: 200))

            if store.connectionState == .error || store.connectionState == .degraded {
                Text(L10n.Nighthawk.Chat.networkHint)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }
}
