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
import Utils
import DarkfiCore

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
        public var useTor: Bool = false
        /// Number of DAG bootstrap messages received
        public var dagSyncCount: Int = 0
        /// Descriptive string for DAG sync progress (e.g. "Syncing DAG… 142 events")
        public var dagSyncProgress: String?
        
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
    
    /// A relay to adapt UniFFI callbacks into an AsyncStream.
    final class ChatEventRelay: DarkircEventCallback, @unchecked Sendable {
        let continuation: AsyncStream<State.Message>.Continuation
        let myNickname: String
        
        init(continuation: AsyncStream<State.Message>.Continuation, myNickname: String = "anon") {
            self.continuation = continuation
            self.myNickname = myNickname
        }
        
        func onMessage(channel: String, nick: String, message: String, timestampMs: UInt64) {
            let msg = State.Message(
                sender: nick,
                content: message,
                channel: channel,
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000),
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
                if state.connectionState == .disconnected {
                    return .send(.connectTapped)
                }
                return .none
                
            case let .scenePhaseChanged(phase):
                switch phase {
                case .inactive, .background:
                    if state.connectionState != .disconnected {
                        return .send(.disconnectTapped)
                    }
                    return .none
                case .active:
                    if state.connectionState == .disconnected {
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
                let nickname = state.nickname
                let useTor = state.useTor
                
                return .run { send in
                    // The embedded darkirc daemon relays public-channel and DM
                    // events through the UniFFI `DarkircEventCallback.on_message`
                    // bridge (NOT a local IRC socket) — identical to Android's
                    // `DarkfiChatController`. We hand the daemon a callback that
                    // funnels messages into an AsyncStream the reducer consumes.
                    let daemon = DarkircDaemonManager.shared
                    daemon.stop()
                    try? await Task.sleep(for: .seconds(1))
                    
                    await send(.embeddedNodeStatusChanged(.starting))
                    await send(.dagSyncStatusUpdate("Starting darkirc node…"))
                    
                    let (stream, continuation) = AsyncStream<State.Message>.makeStream()
                    let relay = ChatEventRelay(continuation: continuation, myNickname: nickname)
                    
                    do {
                        try daemon.start(callback: relay, useTor: useTor)
                    } catch {
                        print("[DarkIRC] Daemon start error: \(error.localizedDescription)")
                        continuation.finish()
                        await send(.ircBridgeError(error.localizedDescription))
                        await send(.connectionStateChanged(.error))
                        await send(.embeddedNodeStatusChanged(.failed))
                        return
                    }
                    
                    await send(.embeddedNodeStatusChanged(.running))
                    await send(.connectionStateChanged(.waitingForDagSync))
                    await send(.dagSyncStatusUpdate("Waiting for P2P peers…"))
                    
                    // Poll darkirc_status() to track daemon/DAG-sync progress.
                    var pollCount = 0
                    let maxPolls = 30
                    while pollCount < maxPolls {
                        try? await Task.sleep(for: .seconds(1))
                        pollCount += 1
                        let ffiStatus = darkircStatus()
                        await send(.dagSyncStatusUpdate("DAG syncing… (\(pollCount)s)"))
                        await send(.embeddedNodeStatusChanged(.syncingDag))
                        if ffiStatus == "failed" {
                            continuation.finish()
                            await send(.ircBridgeError("darkirc daemon failed to start"))
                            await send(.connectionStateChanged(.error))
                            await send(.embeddedNodeStatusChanged(.failed))
                            return
                        }
                        if ffiStatus == "running" && pollCount >= 3 {
                            break
                        }
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
                    state.diagnosticDetail = "Connection to darkirc failed. The darkirc node needs to be running on 127.0.0.1:6667. Check that the embedded darkirc runtime is compiled into the Rust FFI library."
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
                
                let text = state.composedMessage
                let message = State.Message(
                    sender: state.nickname,
                    content: text,
                    channel: channel.name,
                    isOutgoing: true
                )
                state.messages.append(message)
                state.channelMessages[channel.name, default: []].append(message)
                state.composedMessage = ""
                
                // Send natively through the embedded daemon FFI (mirrors
                // Android's `sendChatMessage(channel, nick, body)`), which
                // inserts the event into the EventGraph DAG and broadcasts it.
                let channelTarget = channel.name
                let nick = state.nickname
                return .run { send in
                    do {
                        try sendChatMessage(channel: channelTarget, nick: nick, message: text)
                    } catch {
                        await send(.ircBridgeError("Send failed: \(error.localizedDescription)"))
                    }
                }
                
            case let .messageReceived(message):
                // Track DAG sync message count
                state.dagSyncCount += 1
                state.channelMessages[message.channel, default: []].append(message)
                
                if state.selectedChannel?.name == message.channel {
                    state.messages.append(message)
                } else {
                    // Increment unread for other channels
                    if let idx = state.channels.firstIndex(where: { $0.name == message.channel }) {
                        state.channels[idx].unreadCount += 1
                    }
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
                
            case let .newDmConversation(.presented(.contactSaved(contact))):
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
                // Copy to clipboard
                let shareText = DarkircDmPubkeyParser.formatForSharing(publicKey)
                UIPasteboard.general.string = shareText
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
