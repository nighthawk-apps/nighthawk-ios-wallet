//
//  Chat.swift
//  stealth
//
//  DarkFi IRC chat — connects to embedded darkirc via local IRC bridge.
//  All P2P/event-graph work is done by darkirc; this layer is a TCP IRC
//  client that JOINs channels and reads PRIVMSG lines.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import UIKit
import UserPreferencesStorage
import Utils
import DarkfiCore

// swiftlint:disable type_body_length
@Reducer
public struct Chat {
    @ObservableState
    public struct State: Equatable {
        /// Connection state matching Android DarkfiChatConnectionState.
        public enum ConnectionState: Equatable {
            case disconnected
            case connecting
            case startingDaemon
            case waitingForDagSync
            case connectedDirect
            case connectedViaTor
            case degraded
            case error

            public var isConnected: Bool {
                switch self {
                case .connectedDirect, .connectedViaTor:
                    return true
                default:
                    return false
                }
            }

            public var label: String {
                switch self {
                case .disconnected: return "Disconnected"
                case .connecting: return "Connecting to IRC…"
                case .startingDaemon: return "Starting darkirc node…"
                case .waitingForDagSync: return "Syncing event graph…"
                case .connectedDirect: return "Connected (direct)"
                case .connectedViaTor: return "Connected (Tor)"
                case .degraded: return "Degraded"
                case .error: return "Error"
                }
            }

            public var indicatorColor: String {
                switch self {
                case .connectedDirect, .connectedViaTor: return "green"
                case .connecting, .startingDaemon, .waitingForDagSync, .degraded: return "yellow"
                case .disconnected, .error: return "red"
                }
            }
        }

        /// Embedded darkirc node status matching Android EmbeddedDarkircNodeStatus.
        public enum EmbeddedNodeStatus: Equatable {
            case notUsed
            case starting
            case running
            case waitingForPeers
            case syncingDag
            case ready
            case missingBinary
            case failed

            public var label: String {
                switch self {
                case .notUsed: return "Not used"
                case .starting: return "Starting…"
                case .running: return "Running"
                case .waitingForPeers: return "Finding peers…"
                case .syncingDag: return "Syncing DAG…"
                case .ready: return "Ready"
                case .missingBinary: return "Missing binary"
                case .failed: return "Failed"
                }
            }
        }

        public struct Message: Equatable, Identifiable {
            public let id: String
            public let sender: String
            public let content: String
            public let channel: String
            public let timestamp: Date
            public let isOutgoing: Bool

            public init(
                id: String = UUID().uuidString,
                sender: String,
                content: String,
                channel: String = "",
                timestamp: Date = Date(),
                isOutgoing: Bool = false
            ) {
                self.id = id
                self.sender = sender
                self.content = content
                self.channel = channel
                self.timestamp = timestamp
                self.isOutgoing = isOutgoing
            }
        }

        public struct Channel: Equatable, Identifiable, Hashable {
            public let id: String
            public let name: String
            public let topic: String
            public var unreadCount: Int

            public init(
                id: String? = nil,
                name: String,
                topic: String = "",
                unreadCount: Int = 0
            ) {
                self.id = id ?? name
                self.name = name
                self.topic = topic
                self.unreadCount = unreadCount
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
        }

        public var channels: IdentifiedArrayOf<Channel> = []
        public var selectedChannel: Channel?
        public var messages: IdentifiedArrayOf<Message> = []
        /// All messages keyed by channel name
        public var channelMessages: [String: [Message]] = [:]
        public var composedMessage: String = ""
        public var connectionState: ConnectionState = .disconnected
        public var embeddedNodeStatus: EmbeddedNodeStatus = .notUsed
        public var diagnosticDetail: String?
        /// Persistent hawkXXX nickname — generated once, persists between sessions.
        public var nickname: String = DarkfiChatDefaults.persistentNickname()
        public var useTor: Bool = true
        /// Number of DAG bootstrap messages received
        public var dagSyncCount: Int = 0
        /// Descriptive string for DAG sync progress (e.g. "Syncing DAG… 142 events")
        public var dagSyncProgress: String?
        /// Event IDs already delivered to the UI — prevents duplicate rendering.
        public var seenEventIds: Set<String> = []

        // MARK: - DM state

        /// Channels vs Direct tab selection
        public enum ChatTab: String, Equatable, CaseIterable {
            case channels = "Channels"
            case direct = "Direct"
        }

        public var selectedTab: ChatTab = .channels
        public var dmContacts: [DmContact] = []
        public var dmConversations: [DmConversation] = []
        public var selectedDmContact: DmContact?
        /// DM messages keyed by contact ID
        public var dmMessages: [String: [Message]] = [:]
        /// Show the new DM conversation sheet
        @Presents public var newDmConversation: NewDmConversation.State?
        /// Show share-my-pubkey warning alert
        public var showSharePubkeyWarning: Bool = false
        public var myDmPublicKey: String?

        public init() {
            // Build channels from upstream defaults
            self.channels = IdentifiedArrayOf(
                uniqueElements: DarkfiChatDefaults.defaultPublicChannels.map { name in
                    Channel(
                        name: name,
                        topic: DarkfiChatDefaults.defaultChannelTopics[name] ?? ""
                    )
                }
            )
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case connectTapped
        case retryTapped
        case disconnectTapped
        case connectionStateChanged(State.ConnectionState)
        case embeddedNodeStatusChanged(State.EmbeddedNodeStatus)
        case channelSelected(State.Channel)
        case sendMessage
        case messageReceived(State.Message)
        case removeOptimisticMessage(id: String, channel: String)
        case bootstrapMessagesReceived([State.Message])
        case ircBridgeError(String)
        case dagSyncStatusUpdate(String?)
        case scenePhaseChanged(ScenePhase)
        // DM actions
        case tabSelected(State.ChatTab)
        case newDmTapped
        case newDmConversation(PresentationAction<NewDmConversation.Action>)
        case dmContactSelected(DmContact)
        case dmContactsLoaded([DmContact], [DmConversation])
        case sharePubkeyTapped
        case sharePubkeyConfirmed
        case sharePubkeyCancelled
        case pubkeyGenerated(String)
        case dmMessageReceived(String, State.Message)  // contactId, message
    }

    private enum CancelID { case readLoop, connection }

    @Dependency(\.userStoredPreferences) var userStoredPreferences

    /// A relay to adapt UniFFI callbacks into an AsyncStream.
    final class ChatEventRelay: DarkircEventCallback, @unchecked Sendable {
        let continuation: AsyncStream<State.Message>.Continuation
        let myNickname: String

        init(continuation: AsyncStream<State.Message>.Continuation, myNickname: String = "anon") {
            self.continuation = continuation
            self.myNickname = myNickname
        }

        func onMessage(eventId: String, channel: String, nick: String, message: String, timestamp: UInt64) {
            let msg = State.Message(
                id: eventId,
                sender: nick,
                content: message,
                channel: channel,
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000),
                isOutgoing: nick == myNickname
            )
            continuation.yield(msg)
        }
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.useTor = userStoredPreferences.torForChatEnabled()
                if state.connectionState == .disconnected {
                    return .send(.connectTapped)
                }
                return .none

            case let .scenePhaseChanged(phase):
                switch phase {
                case .inactive, .background:
                    // Do NOT tear down the daemon on every background transition.
                    // The darkirc P2P connection survives short suspensions and
                    // the live relay_task keeps delivering events.  Only stop on
                    // sustained background (handled by the OS killing us).
                    return .none
                case .active:
                    // Check the actual native daemon status, not just UI state.
                    // The daemon may have died while backgrounded but the UI
                    // still shows "connected" because no state update fired.
                    let ffiStatus = darkircStatus()
                    let daemonDead = (ffiStatus == "not_running" || ffiStatus == "failed")
                    let uiDisconnected = (state.connectionState == .disconnected || state.connectionState == .error)

                    if daemonDead || uiDisconnected {
                        // Clear stale message state so the history replay starts fresh
                        state.channelMessages = [:]
                        state.messages = []
                        state.seenEventIds = []
                        if !uiDisconnected {
                            // Daemon died silently — force UI to disconnected first
                            state.connectionState = .disconnected
                        }
                        return .send(.connectTapped)
                    }
                    return .none
                @unknown default:
                    return .none
                }

            case .connectTapped, .retryTapped:
                state.connectionState = .startingDaemon
                state.diagnosticDetail = nil
                state.dagSyncCount = 0
                // Clear stale state so DAG history replay starts fresh
                state.channelMessages = [:]
                state.messages = []
                state.seenEventIds = []
                state.useTor = userStoredPreferences.torForChatEnabled()
                let nickname = state.nickname
                let useTor = state.useTor
                let socksPort = UInt16(userStoredPreferences.torSocksPort() ?? "9050") ?? 9050

                return .run { send in
                    // The embedded darkirc daemon relays public-channel and DM
                    // events through the UniFFI `DarkircEventCallback.on_message`
                    // bridge (NOT a local IRC socket). We hand the daemon a
                    // callback that funnels messages into an AsyncStream the
                    // reducer consumes.
                    let daemon = DarkircDaemonManager.shared

                    await send(.embeddedNodeStatusChanged(.starting))
                    if useTor {
                        await send(.dagSyncStatusUpdate("Tor bootstrapping…"))
                    } else {
                        await send(.dagSyncStatusUpdate("Starting darkirc node…"))
                    }

                    let (stream, continuation) = AsyncStream<State.Message>.makeStream()
                    let relay = ChatEventRelay(continuation: continuation, myNickname: nickname)

                    do {
                        try await daemon.restartForChat(
                            callback: relay,
                            useTor: useTor,
                            torSocksPort: socksPort
                        )
                    } catch {
                        continuation.finish()
                        await send(.ircBridgeError(error.localizedDescription))
                        await send(.connectionStateChanged(.error))
                        await send(.embeddedNodeStatusChanged(.failed))
                        return
                    }

                    await send(.connectionStateChanged(.waitingForDagSync))
                    await send(.dagSyncStatusUpdate("Waiting for P2P peers…"))

                    // Prefer fine-grained `darkirc_connection_phase`; fall back to
                    // STATUS_RUNNING once the daemon is up (pre-phase binaries).
                    var pollCount = 0
                    let maxPolls = 180
                    var ready = false
                    while pollCount < maxPolls {
                        try? await Task.sleep(for: .seconds(1))
                        pollCount += 1
                        let phase = darkircConnectionPhase()
                        let ffiStatus = darkircStatus()
                        let label: String
                        switch phase {
                        case "waiting_for_peers": label = "Waiting for P2P peers…"
                        case "static_sync": label = "Static sync…"
                        case "syncing_dag": label = "Syncing DAG…"
                        case "loading_history": label = "Loading history…"
                        case "connected": label = "Connected"
                        case "starting": label = "Starting…"
                        default: label = "DAG syncing… (\(pollCount)s)"
                        }
                        await send(.dagSyncStatusUpdate(label))

                        if phase == "failed" || ffiStatus == "failed" {
                            continuation.finish()
                            await send(.ircBridgeError("darkirc daemon failed during startup"))
                            await send(.connectionStateChanged(.error))
                            await send(.embeddedNodeStatusChanged(.failed))
                            return
                        }
                        if phase == "connected" {
                            ready = true
                            break
                        }
                        if ffiStatus == "running" {
                            await send(.embeddedNodeStatusChanged(.syncingDag))
                            // Coarse mapping (running → "connected") or rich phase still syncing.
                            let syncing = [
                                "waiting_for_peers", "static_sync", "syncing_dag",
                                "loading_history", "starting",
                            ].contains(phase)
                            if !syncing {
                                ready = true
                                break
                            }
                        }
                    }

                    guard ready else {
                        continuation.finish()
                        await send(.ircBridgeError(
                            "darkirc did not finish sync (status: \(darkircStatus()), phase: \(darkircConnectionPhase()))"
                        ))
                        await send(.connectionStateChanged(.error))
                        await send(.embeddedNodeStatusChanged(.failed))
                        return
                    }

                    await send(.embeddedNodeStatusChanged(.ready))
                    await send(.connectionStateChanged(useTor ? .connectedViaTor : .connectedDirect))
                    await send(.dagSyncStatusUpdate(nil))

                    // Consume incoming messages from the Rust daemon callback
                    // bridge. The daemon also replays historical DAG events
                    // through this same callback after sync completes.
                    for await msg in stream {
                        await send(.messageReceived(msg))
                    }

                    await send(.connectionStateChanged(.disconnected))
                    await send(.embeddedNodeStatusChanged(.notUsed))
                }
                .cancellable(id: CancelID.connection, cancelInFlight: true)

            case .disconnectTapped:
                DarkircDaemonManager.shared.stop()
                state.connectionState = .disconnected
                state.embeddedNodeStatus = .notUsed
                state.diagnosticDetail = nil
                return .cancel(id: CancelID.connection)

            case let .connectionStateChanged(newState):
                state.connectionState = newState
                if newState.isConnected, state.selectedChannel == nil,
                   let first = state.channels.first {
                    state.selectedChannel = first
                    state.messages = IdentifiedArrayOf(
                        uniqueElements: state.channelMessages[first.name] ?? []
                    )
                }
                if case .error = newState {
                    state.diagnosticDetail = "Could not start the embedded darkirc node. Rebuild the Rust FFI with ./scripts/build-darkfi-mobile-ffi-ios.sh, then try Connect again. If it persists, check the Xcode console for P2P/DAG errors."
                } else {
                    state.diagnosticDetail = nil
                }
                return .none

            case let .embeddedNodeStatusChanged(status):
                state.embeddedNodeStatus = status
                return .none

            case let .channelSelected(channel):
                state.selectedChannel = channel
                state.messages = IdentifiedArrayOf(
                    uniqueElements: state.channelMessages[channel.name] ?? []
                )
                // Clear unread
                if let idx = state.channels.index(id: channel.id) {
                    state.channels[idx].unreadCount = 0
                }
                return .none

            case .sendMessage:
                guard !state.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let channel = state.selectedChannel else {
                    return .none
                }

                let text = state.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                state.composedMessage = ""

                // Handle all DarkIRC slash commands as per DarkFi manual
                if text.hasPrefix("/") {
                    let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                    let cmd = parts.first?.lowercased() ?? ""
                    let arg = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

                    switch cmd {
                    case "/nick":
                        if !arg.isEmpty && arg.count <= DarkfiChatDefaults.maxNickLen {
                            let sanitized = DarkfiChatDefaults.sanitizeNickname(arg)
                            state.nickname = sanitized
                            DarkfiChatDefaults.setNickname(sanitized)
                            let sysMsg = State.Message(
                                id: UUID().uuidString,
                                sender: "System",
                                content: "Your nickname is now: \(sanitized)",
                                channel: channel.name,
                                timestamp: Date(),
                                isOutgoing: false
                            )
                            state.messages.append(sysMsg)
                            state.channelMessages[channel.name, default: []].append(sysMsg)
                            return .none
                        }
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Invalid nickname. Usage: /nick <name> (1–24 alphanumeric/underscore characters)",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    case "/join":
                        if !arg.isEmpty {
                            let targetChan = arg.hasPrefix("#") ? arg : "#\(arg)"
                            if state.channels[id: targetChan] == nil {
                                let newChan = State.Channel(name: targetChan)
                                state.channels.append(newChan)
                            }
                            if let ch = state.channels[id: targetChan] {
                                state.selectedChannel = ch
                                state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[ch.name] ?? [])
                            }
                            let sysMsg = State.Message(
                                id: UUID().uuidString,
                                sender: "System",
                                content: "Joined channel: \(targetChan)",
                                channel: targetChan,
                                timestamp: Date(),
                                isOutgoing: false
                            )
                            state.messages.append(sysMsg)
                            state.channelMessages[targetChan, default: []].append(sysMsg)
                            return .none
                        }
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Usage: /join <#channel>",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    case "/part", "/leave":
                        let targetChan = channel.name
                        state.channels.remove(id: targetChan)
                        state.channelMessages.removeValue(forKey: targetChan)
                        if let first = state.channels.first {
                            state.selectedChannel = first
                            state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[first.name] ?? [])
                        } else {
                            state.selectedChannel = nil
                            state.messages = []
                        }
                        return .none

                    case "/clear":
                        state.channelMessages[channel.name] = []
                        state.messages = []
                        return .none

                    case "/me":
                        if !arg.isEmpty {
                            let actionText = "* \(state.nickname) \(arg)"
                            let message = State.Message(
                                sender: state.nickname,
                                content: actionText,
                                channel: channel.name,
                                isOutgoing: true
                            )
                            state.messages.append(message)
                            state.channelMessages[channel.name, default: []].append(message)
                            state.seenEventIds.insert(message.id)

                            let channelTarget = channel.name
                            let nick = state.nickname
                            let optimisticId = message.id
                            return .run { send in
                                do {
                                    try sendChatMessage(channel: channelTarget, nick: nick, message: actionText)
                                } catch {
                                    await send(.ircBridgeError("Send failed: \(error.localizedDescription)"))
                                    await send(.removeOptimisticMessage(id: optimisticId, channel: channelTarget))
                                }
                            }
                        }
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Usage: /me <action>",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    case "/msg":
                        let msgParts = arg.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                        if msgParts.count == 2 {
                            let target = String(msgParts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                            let msgContent = String(msgParts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                            let nick = state.nickname
                            return .run { send in
                                do {
                                    try sendChatMessage(channel: target, nick: nick, message: msgContent)
                                } catch {
                                    await send(.ircBridgeError("Send /msg failed: \(error.localizedDescription)"))
                                }
                            }
                        }
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Usage: /msg <target> <message>",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    case "/help":
                        let helpText = """
                        Available DarkIRC commands:
                          /nick <name> — Change nickname (1–24 characters)
                          /join <#channel> — Join or switch to channel
                          /part — Leave current channel
                          /clear — Clear messages in current view
                          /me <action> — Send action message (* nick action)
                          /msg <target> <text> — Send message to channel or nick
                          /help — Show this help message
                        """
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: helpText,
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none

                    default:
                        let sysMsg = State.Message(
                            id: UUID().uuidString,
                            sender: "System",
                            content: "Unknown command '\(cmd)'. Type /help for DarkIRC commands.",
                            channel: channel.name,
                            timestamp: Date(),
                            isOutgoing: false
                        )
                        state.messages.append(sysMsg)
                        state.channelMessages[channel.name, default: []].append(sysMsg)
                        return .none
                    }
                }

                // Optimistic local insert for both public channels and DMs.
                // Public sends previously waited only on EventGraph self-echo,
                // which often never reached the UI while status already showed
                // Connected — making "hi" vanish from #dev.
                let message = State.Message(
                    sender: state.nickname,
                    content: text,
                    channel: channel.name,
                    isOutgoing: true
                )
                state.messages.append(message)
                state.channelMessages[channel.name, default: []].append(message)
                state.seenEventIds.insert(message.id)

                let channelTarget = channel.name
                let nick = state.nickname
                let optimisticId = message.id
                return .run { send in
                    do {
                        try sendChatMessage(channel: channelTarget, nick: nick, message: text)
                    } catch {
                        await send(.ircBridgeError("Send failed: \(error.localizedDescription)"))
                        await send(.removeOptimisticMessage(id: optimisticId, channel: channelTarget))
                    }
                }

            case let .messageReceived(message):
                // Deduplicate: skip if this event was already delivered
                guard !state.seenEventIds.contains(message.id) else {
                    return .none
                }
                state.seenEventIds.insert(message.id)

                // Prune to cap memory: seenEventIds grows with every received
                // event. Once we exceed 10k we drop the set — all live messages
                // are already in channelMessages so dups are unlikely at this
                // point.
                if state.seenEventIds.count > 10_000 {
                    state.seenEventIds = []
                }

                // Replace optimistic local bubbles (UUID ids) with the real
                // EventGraph echo (same sender + content on the same channel).
                let isOptimisticLocal: (State.Message) -> Bool = { local in
                    local.isOutgoing &&
                        local.sender == message.sender &&
                        local.content == message.content &&
                        local.id != message.id &&
                        UUID(uuidString: local.id) != nil
                }

                var bucket = state.channelMessages[message.channel] ?? []
                let removedIds = Set(bucket.filter(isOptimisticLocal).map(\.id))
                bucket.removeAll(where: isOptimisticLocal)
                bucket.append(message)
                state.channelMessages[message.channel] = bucket
                for removed in removedIds {
                    state.seenEventIds.remove(removed)
                }

                if state.selectedChannel?.name == message.channel {
                    state.messages.removeAll(where: isOptimisticLocal)
                    state.messages.append(message)
                } else if let idx = state.channels.firstIndex(where: { $0.name == message.channel }) {
                    state.channels[idx].unreadCount += 1
                }

                state.dagSyncCount += 1
                return .none

            case let .removeOptimisticMessage(id, channel):
                state.seenEventIds.remove(id)
                state.channelMessages[channel]?.removeAll { $0.id == id }
                if state.selectedChannel?.name == channel {
                    state.messages.removeAll { $0.id == id }
                }
                return .none

            case let .dagSyncStatusUpdate(progress):
                state.dagSyncProgress = progress
                return .none

            case let .bootstrapMessagesReceived(messages):
                state.dagSyncCount = messages.count
                for msg in messages {
                    state.channelMessages[msg.channel, default: []].append(msg)
                }

                // Load messages for selected channel
                if let selected = state.selectedChannel {
                    state.messages = IdentifiedArrayOf(
                        uniqueElements: state.channelMessages[selected.name] ?? []
                    )
                }
                return .none

            case let .ircBridgeError(detail):
                state.diagnosticDetail = detail
                return .none

            // MARK: - DM actions

            case let .tabSelected(tab):
                state.selectedTab = tab
                if tab == .direct {
                    // Load DM contacts from store
                    return .run { send in
                        let contacts = await DarkircCryptoStore.shared.allContacts()
                        let convos = await DarkircCryptoStore.shared.allConversations()
                        await send(.dmContactsLoaded(contacts, convos))
                    }
                }
                return .none

            case .newDmTapped:
                state.newDmConversation = NewDmConversation.State()
                return .none

            case .newDmConversation(.presented(.dismiss)):
                state.newDmConversation = nil
                // Refresh contacts
                return .run { send in
                    let contacts = await DarkircCryptoStore.shared.allContacts()
                    let convos = await DarkircCryptoStore.shared.allConversations()
                    await send(.dmContactsLoaded(contacts, convos))
                }

            case .newDmConversation(.presented(.contactSaved)):
                // No darkirc.toml config regeneration is needed anymore.
                return .none

            case .newDmConversation:
                return .none

            case let .dmContactSelected(contact):
                state.selectedDmContact = contact
                state.messages = IdentifiedArrayOf(
                    uniqueElements: state.dmMessages[contact.id] ?? []
                )
                // Clear unread
                return .run { _ in
                    await DarkircCryptoStore.shared.clearUnread(contactId: contact.id)
                }

            case let .dmContactsLoaded(contacts, convos):
                state.dmContacts = contacts
                state.dmConversations = convos
                return .none

            case .sharePubkeyTapped:
                state.showSharePubkeyWarning = true
                return .none

            case .sharePubkeyConfirmed:
                state.showSharePubkeyWarning = false
                return .run { send in
                    if let kp = DarkircContactManager.generateKeypair() {
                        await send(.pubkeyGenerated(kp.publicB58))
                    }
                }

            case .sharePubkeyCancelled:
                state.showSharePubkeyWarning = false
                return .none

            case let .pubkeyGenerated(publicKey):
                state.myDmPublicKey = publicKey
                // Copy to clipboard with 60-second auto-expiry
                let shareText = DarkircDmPubkeyParser.formatForSharing(publicKey)
                UIPasteboard.general.setItems(
                    [[UIPasteboard.typeAutomatic: shareText]],
                    options: [.expirationDate: Date().addingTimeInterval(60)]
                )
                return .none

            case let .dmMessageReceived(contactId, message):
                state.dmMessages[contactId, default: []].append(message)
                if state.selectedDmContact?.id == contactId {
                    state.messages.append(message)
                }
                return .none
            }
        }
        .ifLet(\.$newDmConversation, action: \.newDmConversation) {
            NewDmConversation()
        }
    }

    public init() {}
}
// swiftlint:enable type_body_length
