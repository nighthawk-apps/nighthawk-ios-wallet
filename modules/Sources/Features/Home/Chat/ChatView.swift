//
//  ChatView.swift
//  stealth
//
//  DarkFi IRC chat view.
//  Displays channels, messages, and a compose bar.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

struct ChatView: View {
    @Bindable var store: StoreOf<Chat>
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        VStack(spacing: 0) {
            // Connection status bar (always visible)
            connectionStatusBar
            
            switch true {
            case store.connectionState.isConnected:
                connectedView
            case store.connectionState == .startingDaemon,
                 store.connectionState == .connecting,
                 store.connectionState == .waitingForDagSync:
                connectingView
            default:
                disconnectedView
            }
        }
        .onAppear { store.send(.onAppear) }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Connection Status Bar (matches Android ChatStatusRow)
private extension ChatView {
    var connectionStatusBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Embedded node status (if used)
            if store.embeddedNodeStatus != .notUsed {
                HStack(spacing: 8) {
                    statusDot(for: store.embeddedNodeStatus)
                    Text("Node: \(store.embeddedNodeStatus.label)")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                }
            }
            
            // IRC connection status + nickname
            HStack(spacing: 8) {
                connectionDot
                Text("IRC: \(store.connectionState.label)")
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                
                Spacer()
                
                // Show persistent nickname
                Text(store.nickname)
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                
                // Retry button
                if store.connectionState == .error || store.connectionState == .disconnected {
                    Button(action: { store.send(.retryTapped) }) {
                        Text("Retry")
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 12))
                            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    }
                }
            }
            
            // Tor routing label
            HStack(spacing: 4) {
                Text(store.useTor ? "Tor" : "Direct")
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.6))
                Text("·")
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.4))
                Text(store.connectionState.label)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.6))
            }
            
            // Diagnostic detail
            if let detail = store.diagnosticDetail {
                Text(detail)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                    .foregroundColor(
                        store.connectionState == .error
                        ? Color.red.opacity(0.8)
                        : Asset.Colors.Nighthawk.parmaviolet.color
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Asset.Colors.Nighthawk.navy.color.opacity(0.6))
    }
    
    var connectionDot: some View {
        Circle()
            .fill(connectionColor)
            .frame(width: 8, height: 8)
    }
    
    var connectionColor: Color {
        switch store.connectionState {
        case .connectedDirect, .connectedViaTor: return .green
        case .connecting, .startingDaemon, .waitingForDagSync, .degraded: return .yellow
        case .disconnected, .error: return .red.opacity(0.6)
        }
    }
    
    func statusDot(for status: Chat.State.EmbeddedNodeStatus) -> some View {
        Circle()
            .fill(embeddedNodeColor(for: status))
            .frame(width: 8, height: 8)
    }
    
    func embeddedNodeColor(for status: Chat.State.EmbeddedNodeStatus) -> Color {
        switch status {
        case .running, .ready: return .green
        case .starting, .waitingForPeers, .syncingDag: return .yellow
        case .notUsed: return .gray
        case .missingBinary, .failed: return .red.opacity(0.6)
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
            
            Text("DarkFi IRC")
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 28))
                .foregroundColor(.white)
            
            Text("End-to-end encrypted chat\npowered by the DarkFi P2P network")
                .multilineTextAlignment(.center)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .padding(.horizontal, 40)
            
            Button(action: { store.send(.connectTapped) }) {
                Text("Connect")
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
            }
            .buttonStyle(.nighthawkPrimary(width: 200))
            
            if store.connectionState == .error || store.connectionState == .degraded {
                Text("Check your network settings or configure Tor in Settings.")
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    /// View shown during the multi-step connection process
    var connectingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(Asset.Colors.Nighthawk.peach.color)
                .padding(.bottom, 16)
            
            Text(store.connectionState.label)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 20))
                .foregroundColor(.white)
            
            // Show node status details
            VStack(spacing: 8) {
                statusLine("You", status: store.nickname)
                statusLine("darkirc node", status: store.embeddedNodeStatus.label)
                statusLine("IRC bridge", status: store.connectionState.label)
                if let dagProgress = store.dagSyncProgress {
                    statusLine("Event graph", status: dagProgress)
                }
                if store.dagSyncCount > 0 {
                    statusLine("Messages", status: "\(store.dagSyncCount) received")
                }
            }
            .padding(.horizontal, 40)
            
            Text("Connecting to the DarkFi P2P network and syncing the event graph. This may take up to 30 seconds on first launch.")
                .multilineTextAlignment(.center)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    func statusLine(_ label: String, status: String) -> some View {
        HStack {
            Text(label)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            Spacer()
            Text(status)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Connected State
private extension ChatView {
    var connectedView: some View {
        VStack(spacing: 0) {
            // Channels / Direct segmented control
            tabSelector
            
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
            Button("Generate & Copy", action: { store.send(.sharePubkeyConfirmed) })
            Button("Cancel", role: .cancel, action: { store.send(.sharePubkeyCancelled) })
        } message: {
            Text("This will generate a new DM keypair and copy your public key to the clipboard. Share it with your peer via a secure channel. Anyone with this key can send you encrypted DMs.")
        }
    }
    
    var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Chat.State.ChatTab.allCases, id: \.self) { tab in
                Button(action: { store.send(.tabSelected(tab)) }) {
                    Text(tab.rawValue)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                        .foregroundColor(store.selectedTab == tab ? .white : Asset.Colors.Nighthawk.parmaviolet.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            store.selectedTab == tab
                            ? Asset.Colors.Nighthawk.peach.color.opacity(0.2)
                            : Color.clear
                        )
                }
            }
        }
        .background(Asset.Colors.Nighthawk.navy.color.opacity(0.8))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Asset.Colors.Nighthawk.peach.color.opacity(0.3))
                .frame(height: 1)
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
                .foregroundColor(isSelected ? .white : Asset.Colors.Nighthawk.parmaviolet.color)
            
            if channel.unreadCount > 0 {
                Text("\(channel.unreadCount)")
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Asset.Colors.Nighthawk.peach.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Asset.Colors.Nighthawk.peach.color.opacity(0.2) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.3),
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
                        Text("New DM")
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
                        Text("Share Key")
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
                        .foregroundColor(.white.opacity(0.8))
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
        return HStack(spacing: 14) {
            // Avatar circle
            Circle()
                .fill(Asset.Colors.Nighthawk.peach.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(contact.contactLabel.prefix(1)).uppercased())
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.contactLabel)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                    .foregroundColor(.white)
                
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Asset.Colors.Nighthawk.peach.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
    
    // MARK: - DM Conversation Header
    
    var dmConversationHeader: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Go back to DM list
                store.send(.dmContactSelected(store.selectedDmContact!))
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
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
                        .foregroundColor(.white)
                    Text("E2E encrypted")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.7))
                }
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(.green.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Asset.Colors.Nighthawk.navy.color.opacity(0.8))
    }
    
    var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if store.messages.isEmpty {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 60)
                            Text("No messages yet")
                                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            Text("Say something in \(store.selectedChannel?.name ?? store.selectedDmContact?.contactLabel ?? "this chat")")
                                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.6))
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
    
    func messageBubble(_ message: Chat.State.Message) -> some View {
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
                    .foregroundColor(.white)
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
                
                Text(message.timestamp, style: .time)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.6))
            }
            
            if !message.isOutgoing { Spacer(minLength: 60) }
        }
    }
    
    var composeBar: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $store.composedMessage)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Asset.Colors.Nighthawk.navy.color)
                )
                .onSubmit { store.send(.sendMessage) }
            
            Button(action: { store.send(.sendMessage) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        store.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.3)
                        : Asset.Colors.Nighthawk.peach.color
                    )
            }
            .disabled(store.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Asset.Colors.Nighthawk.darkNavy.color)
    }
}
