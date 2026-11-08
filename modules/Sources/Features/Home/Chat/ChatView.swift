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
    @State private var showPeers = false
    @ObservedObject private var themes = NighthawkThemeController.shared
    @ObservedObject private var mesh = NighthawkMeshController.shared

    var body: some View {
        VStack(spacing: 0) {
            inboxBar

            switch store.connectionState {
            case .disconnected, .error:
                disconnectedView
            default:
                connectedView
            }
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
private extension ChatView {
    /// Theme-aware selection container & accent (magenta in Cyberpunk, slate in Stealth, neutral in Paper).
    private var chatSelectionPink: Color { themes.theme.secondaryContainerColor }
    private var chatSelectionPinkBright: Color { themes.theme.secondaryAccentColor }
    private var chatSelectionOnPink: Color { themes.theme.onSecondaryContainerColor }

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
                connectionStatusBody
                Text("Nearby mesh")
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .padding(.top, 8)
                Text(mesh.statusLine)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(4)
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
            // Embedded node status (if used)
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

            // IRC connection status + nickname
            HStack(spacing: 8) {
                connectionDot
                Text(L10n.Nighthawk.Chat.ircStatus(store.connectionState.label))
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                // Show persistent nickname
                Text(store.nickname)
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    .lineLimit(1)

                // Retry button
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

            // One summary line, matching Android chatConnectionSummary.
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

            // Diagnostic detail — capped like Android CONNECTION_STATUS_MAX_LINES.
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

    var peerSlots: [(index: Int, label: String, connected: Bool)] {
        let connecting = store.connectionState == .startingDaemon
            || store.connectionState == .connecting
            || store.connectionState == .waitingForDagSync
        return (0..<3).map { index in
            if store.connectionState.isConnected && index == 0 {
                return (index, "connected", true)
            }
            if connecting {
                return (index, "connecting", false)
            }
            return (index, "sleeping", false)
        }
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
private extension ChatView {
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

// MARK: - Connected State
private extension ChatView {
    var connectedView: some View {
        VStack(spacing: 0) {
            switch store.selectedTab {
            case .channels:
                // Channel tabs + messages + compose
                VStack(spacing: 0) {
                    channelBar
                    messagesList
                    composeBar
                }
            case .direct:
                // DM contacts list or DM conversation
                if store.selectedDmContact != nil {
                    VStack(spacing: 0) {
                        dmConversationHeader
                        messagesList
                        composeBar
                    }
                } else {
                    dmContactsList
                }
            }
        }
        .sheet(item: $store.scope(state: \.newDmConversation, action: \.newDmConversation)) { dmStore in
            NewDmConversationView(store: dmStore)
                .presentationDetents([.large])
        }
        .alert("Share Your Public Key", isPresented: $store.showSharePubkeyWarning) {
            Button("Copy public key", action: { store.send(.sharePubkeyConfirmed) })
            Button("Cancel", role: .cancel, action: { store.send(.sharePubkeyCancelled) })
        } message: {
            Text("Copies your DM public key. A keypair is created only the first time. Share it over a channel you trust. Anyone with this key can send you encrypted DMs.")
        }
    }

    var channelBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.channels) { channel in
                    channelPill(channel)
                        .onTapGesture {
                            store.send(.channelSelected(channel))
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Asset.Colors.Nighthawk.navy.color.opacity(0.8))
    }

    func channelPill(_ channel: Chat.State.Channel) -> some View {
        let isSelected = store.selectedChannel == channel
        return HStack(spacing: 4) {
            Text(channel.name)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                .foregroundColor(isSelected ? chatSelectionOnPink : Asset.Colors.Nighthawk.parmaviolet.color)

            if channel.unreadCount > 0 {
                Text("\(channel.unreadCount)")
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 11))
                    .foregroundColor(StealthTheme.Colors.onPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(chatSelectionPinkBright)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(minHeight: 36)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? chatSelectionPink.opacity(themes.theme.usesCyberpunkChrome ? 0.38 : 1.0) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? chatSelectionPinkBright.opacity(0.55) : Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - DM Contacts List

    var dmContactsList: some View {
        VStack(spacing: 0) {
            // Action buttons
            HStack(spacing: 12) {
                Button(action: { store.send(.newDmTapped) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text(L10n.Nighthawk.Chat.newDm)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                    }
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Asset.Colors.Nighthawk.peach.color.opacity(0.15))
                    )
                }

                Button(action: { store.send(.sharePubkeyTapped) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 12))
                        Text(L10n.Nighthawk.Chat.shareKey)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                    }
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().stroke(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.3))
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // My pubkey if generated
            if let myKey = store.myDmPublicKey {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MY PUBLIC KEY (copied)")
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 11))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .tracking(1.2)
                    Text(myKey)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color.opacity(0.8))
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Asset.Colors.Nighthawk.navy.color.opacity(0.5))
            }

            // Contact list
            if store.dmContacts.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.4))

                    Text("No DM contacts")
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

                    Text("Tap \"New DM\" to exchange ChaCha20 public keys with a peer and start an encrypted conversation.")
                        .multilineTextAlignment(.center)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.6))
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.dmContacts) { contact in
                            dmContactRow(contact)
                                .onTapGesture {
                                    store.send(.dmContactSelected(contact))
                                }
                        }
                    }
                }
            }
        }
    }

    func dmContactRow(_ contact: DmContact) -> some View {
        let convo = store.dmConversations.first { $0.id == contact.id }
        let isSelected = store.selectedDmContact?.id == contact.id
        return HStack(spacing: 14) {
            // Avatar circle
            Circle()
                .fill(chatSelectionPink.opacity(0.45))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(contact.contactLabel.prefix(1)).uppercased())
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                        .foregroundColor(chatSelectionPinkBright)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.contactLabel)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                if let lastMsg = convo?.lastMessageText {
                    Text(lastMsg)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let unread = convo?.unreadCount, unread > 0 {
                Text("\(unread)")
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(chatSelectionPinkBright)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? chatSelectionPink.opacity(themes.theme.usesCyberpunkChrome ? 0.32 : 0.4) : Color.clear)
    }

    // MARK: - DM Conversation Header

    var dmConversationHeader: some View {
        HStack(spacing: 8) {
            Button(action: { store.send(.dmBackTapped) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            if let contact = store.selectedDmContact {
                Circle()
                    .fill(Asset.Colors.Nighthawk.peach.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(contact.contactLabel.prefix(1)).uppercased())
                            .font(.custom(FontFamily.PulpDisplay.bold.name, size: 14))
                            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.contactLabel)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    Text("E2E encrypted")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.7))
                }
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(StealthTheme.Colors.statusSuccess)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Asset.Colors.Nighthawk.navy.color.opacity(0.8))
    }

    var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if store.messages.isEmpty {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 60)
                            if store.connectionState.isConnected {
                                Text(L10n.Nighthawk.Chat.noMessages)
                                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            } else {
                                ProgressView()
                                    .tint(Asset.Colors.Nighthawk.peach.color)
                                Text(store.connectionState.label)
                                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        ForEach(store.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: store.messages.count) {
                if let last = store.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func messageBubble(_ message: Chat.State.Message) -> some View {
        if message.failedToDecrypt {
            Text(L10n.Nighthawk.Chat.couldNotDecrypt)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 6)
        } else {
            messageContent(message)
        }
    }

    func messageContent(_ message: Chat.State.Message) -> some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                if !message.isOutgoing {
                    Text(message.sender)
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                }

                Text(message.content)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 15))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                message.isOutgoing
                                    ? Asset.Colors.Nighthawk.peach.color.opacity(0.25)
                                    : Asset.Colors.Nighthawk.navy.color
                            )
                    )
                    .textSelection(.enabled)
                    .contextMenu {
                        Button {
                            // Match DM pubkey share: local-only + 60s expiry.
                            UIPasteboard.general.setItems(
                                [[UIPasteboard.typeAutomatic: message.content]],
                                options: [
                                    .localOnly: true,
                                    .expirationDate: Date().addingTimeInterval(60)
                                ]
                            )
                        } label: {
                            Label("Copy Message", systemImage: "doc.on.doc")
                        }
                    }

                Text(message.timestamp, style: .time)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.6))
            }

            if !message.isOutgoing { Spacer(minLength: 60) }
        }
    }

    var composeBar: some View {
        let canSend = store.connectionState.isConnected
            && !store.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(spacing: 12) {
            TextField("Message", text: $store.composedMessage)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 15))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Asset.Colors.Nighthawk.navy.color)
                )
                .disabled(!store.connectionState.isConnected)
                .onSubmit { store.send(.sendMessage) }

            Button(action: { store.send(.sendMessage) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        canSend
                            ? Asset.Colors.Nighthawk.peach.color
                            : Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.3)
                    )
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(chatBackdrop)
    }

    private var chatBackdrop: Color {
        themes.theme.usesCyberpunkChrome
            ? Color.black.opacity(0.45)
            : Asset.Colors.Nighthawk.darkNavy.color
    }
}
