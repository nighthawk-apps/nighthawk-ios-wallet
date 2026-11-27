//
//  Chat.swift
//  stealth
//
//  DarkFi IRC chat reducer — connects to embedded darkirc via UniFFI event bridge.
//

import ComposableArchitecture
import DarkfiCore
import Foundation
import Generated
import Models
import SwiftUI
import UIKit
import UserPreferencesStorage
import Utils

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
            case connectedViaNym
            case degraded
            case error

            public var isConnected: Bool {
                switch self {
                case .connectedDirect, .connectedViaTor, .connectedViaNym:
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
                case .connectedViaNym: return "Connected (Nym)"
                case .degraded: return "Degraded"
                case .error: return "Error"
                }
            }

            public var indicatorColor: String {
                switch self {
                case .connectedDirect, .connectedViaTor, .connectedViaNym: return "green"
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
            public let failedToDecrypt: Bool

            public init(
                id: String = UUID().uuidString,
                sender: String,
                content: String,
                channel: String = "",
                timestamp: Date = Date(),
                isOutgoing: Bool = false,
                failedToDecrypt: Bool = false
            ) {
                self.id = id
                self.sender = sender
                self.content = content
                self.channel = channel
                self.timestamp = timestamp
                self.isOutgoing = isOutgoing
                self.failedToDecrypt = failedToDecrypt
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

        public enum ChatTab: String, Equatable, CaseIterable {
            case channels = "Channels"
            case direct = "Direct"
        }

        public var channels: IdentifiedArrayOf<Channel> = []
        public var selectedChannel: Channel?
        public var messages: IdentifiedArrayOf<Message> = []
        public var channelMessages: [String: [Message]] = [:]
        public var composedMessage: String = ""
        public var composerDrafts: [String: String] = [:]

        public var composerKey: String {
            selectedTab == .direct
                ? "dm:\(selectedDmContact?.id ?? "")"
                : "ch:\(selectedChannel?.id ?? "")"
        }

        mutating func moveComposer(from previous: String) {
            let next = composerKey
            guard previous != next else { return }
            if composedMessage.isEmpty {
                composerDrafts.removeValue(forKey: previous)
            } else {
                composerDrafts[previous] = composedMessage
            }
            composedMessage = composerDrafts[next] ?? ""
        }

        public var connectionState: ConnectionState = .disconnected
        public var fudNotice: String?
        public var embeddedNodeStatus: EmbeddedNodeStatus = .notUsed
        public var diagnosticDetail: String?
        public var nickname: String = DarkfiChatDefaults.persistentNickname()
        public var receiveAddress: String = ""
        public var chainTip: Int = 0
        public var lightStatusMessage: String?
        public var privacyNetwork: NighthawkSetting.PrivacyNetwork = .default
        public var dagSyncCount: Int = 0
        public var dagSyncProgress: String?
        public var seenEventIds: Set<String> = []

        public var selectedTab: ChatTab = .channels
        public var dmContacts: [DmContact] = []
        public var dmConversations: [DmConversation] = []
        public var selectedDmContact: DmContact?
        public var dmMessages: [String: [Message]] = [:]
        @Presents public var newDmConversation: NewDmConversation.State?
        public var showSharePubkeyWarning: Bool = false
        public var myDmPublicKey: String?

        public init() {
            let defaults = DarkfiChatDefaults.defaultPublicChannels.map { name in
                Channel(
                    name: name,
                    topic: DarkfiChatDefaults.defaultChannelTopics[name] ?? ""
                )
            }
            self.channels = IdentifiedArrayOf(uniqueElements: defaults)
            self.selectedChannel = defaults.first
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case connectTapped
        case retryTapped
        case disconnectTapped
        case connectionStateChanged(State.ConnectionState)
        case fudOfferTapped(String, meshOn: Bool)
        case dismissFudNotice
        case embeddedNodeStatusChanged(State.EmbeddedNodeStatus)
        case channelSelected(State.Channel)
        case sendMessage
        case messageReceived(State.Message)
        case removeOptimisticMessage(id: String, channel: String)
        case removeOptimisticDm(id: String, contactId: String)
        case bootstrapMessagesReceived([State.Message])
        case ircBridgeError(String)
        case dagSyncStatusUpdate(String?)
        case scenePhaseChanged(ScenePhase)
        case tabSelected(State.ChatTab)
        case newDmTapped
        case newDmConversation(PresentationAction<NewDmConversation.Action>)
        case dmContactSelected(DmContact)
        case dmContactsLoaded([DmContact], [DmConversation])
        case dmBackTapped
        case sharePubkeyTapped
        case sharePubkeyConfirmed
        case sharePubkeyCancelled
        case dmKeypairMinted(secret: String, publicKey: String)
        case pubkeyGenerated(String)
        case dmMessageReceived(String, State.Message)
        case settingsTapped
        case requestMoneyTapped
        case payInvoiceTapped(address: String, amount: String?, memo: String?)
        case walletRequest(amount: String, memo: String)
        case walletSend(address: String, amount: String, memo: String, tip: Bool)
        case postBroadcastedReceipt(ChatReceipt, channel: String?)
        case openNotifiedThread(String)
        case retryOutgoing(channel: String, text: String)
        case markOutgoingSent(id: String, channel: String)
        case markOutgoingFailed(id: String, channel: String)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case openChatSettings
            case requestMoney
            case payInvoice(address: String, amount: String?, memo: String?)
        }
    }

    enum CancelID { case readLoop, connection }

    @Dependency(\.userStoredPreferences) var userStoredPreferences

    public var body: some ReducerOf<Self> {
        BindingReducer()

        lifecycleReducer()
        channelMessagingReducer()
        walletAndDeliveryReducer()
        directMessageReducer()
            .ifLet(\.$newDmConversation, action: \.newDmConversation) {
                NewDmConversation()
            }
    }

    public init() {}
}

// MARK: - Modular Sub-Reducers
private extension Chat {
    func lifecycleReducer() -> Reduce<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.privacyNetwork = SessionPrivacyOverride.resolved(
                    stored: userStoredPreferences.walletPrivacyNetwork()
                )
                restoreChatHistoryIfEmpty(&state)
                return state.connectionState == .disconnected ? .send(.connectTapped) : .none
            case let .scenePhaseChanged(phase):
                return handleScenePhase(phase, state: &state)
            case .connectTapped, .retryTapped:
                return handleConnect(state: &state)
            case .disconnectTapped:
                DarkircDaemonManager.shared.stop()
                state.connectionState = .disconnected
                state.embeddedNodeStatus = .notUsed
                state.diagnosticDetail = nil
                return .cancel(id: CancelID.connection)
            case .dismissFudNotice:
                state.fudNotice = nil
                return .none
            case let .fudOfferTapped(raw, meshOn):
                return handleFudOffer(raw: raw, meshOn: meshOn, state: &state)
            case let .connectionStateChanged(newState):
                return handleConnectionStateChanged(newState, state: &state)
            case let .embeddedNodeStatusChanged(status):
                state.embeddedNodeStatus = status
                return .none
            default:
                return .none
            }
        }
    }

    func channelMessagingReducer() -> Reduce<State, Action> {
        Reduce { state, action in
            switch action {
            case let .channelSelected(channel):
                return handleChannelSelected(channel, state: &state)
            case .sendMessage:
                return handleSendMessage(state: &state)
            case let .messageReceived(message):
                return handleMessageReceived(message, state: &state)
            case let .removeOptimisticMessage(id, channel):
                return handleRemoveOptimistic(id: id, channel: channel, contactId: nil, state: &state)
            case let .removeOptimisticDm(id, contactId):
                return handleRemoveOptimistic(id: id, channel: nil, contactId: contactId, state: &state)
            case let .dagSyncStatusUpdate(progress):
                state.dagSyncProgress = progress
                return .none
            case let .bootstrapMessagesReceived(messages):
                return handleBootstrapMessages(messages, state: &state)
            case let .ircBridgeError(detail):
                state.diagnosticDetail = detail
                return .none
            default:
                return .none
            }
        }
    }

    func handleChannelSelected(_ channel: State.Channel, state: inout State) -> Effect<Action> {
        let previous = state.composerKey
        state.selectedChannel = channel
        state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[channel.name] ?? [])
        state.moveComposer(from: previous)
        if let idx = state.channels.index(id: channel.id) {
            state.channels[idx].unreadCount = 0
        }
        return .none
    }

    func handleRemoveOptimistic(
        id: String,
        channel: String?,
        contactId: String?,
        state: inout State
    ) -> Effect<Action> {
        state.seenEventIds.remove(id)
        if let channel {
            state.channelMessages[channel]?.removeAll { $0.id == id }
            if state.selectedChannel?.name == channel {
                state.messages.removeAll { $0.id == id }
            }
        }
        if let contactId {
            state.dmMessages[contactId]?.removeAll { $0.id == id }
            if state.selectedDmContact?.id == contactId {
                state.messages.removeAll { $0.id == id }
            }
        }
        return .none
    }

    func walletAndDeliveryReducer() -> Reduce<State, Action> {
        Reduce { state, action in
            switch action {
            case .settingsTapped, .requestMoneyTapped, .payInvoiceTapped:
                return handleWalletDelegateForwarding(action)
            case let .walletRequest(amount, memo):
                return handleWalletRequest(amount: amount, memo: memo, state: &state)
            case let .walletSend(address, amount, memo, tip):
                return handleWalletSend(address: address, amount: amount, memo: memo, tip: tip, state: &state)
            case let .postBroadcastedReceipt(receipt, channel):
                return handlePostBroadcastedReceipt(receipt, channel: channel, state: &state)
            case let .openNotifiedThread(thread):
                return handleOpenNotifiedThread(thread, state: &state)
            case let .retryOutgoing(channel, text):
                return handleRetryOutgoing(channel: channel, text: text, state: &state)
            case let .markOutgoingSent(id, channel):
                return updateOutgoingDelivery(state: &state, oldId: id, newId: "local-\(UUID().uuidString)", channel: channel)
            case let .markOutgoingFailed(id, channel):
                return handleMarkOutgoingFailed(id: id, channel: channel, state: &state)
            default:
                return .none
            }
        }
    }

    func handleWalletDelegateForwarding(_ action: Action) -> Effect<Action> {
        switch action {
        case .settingsTapped:
            return .send(.delegate(.openChatSettings))
        case .requestMoneyTapped:
            return .send(.delegate(.requestMoney))
        case let .payInvoiceTapped(address, amount, memo):
            return .send(.delegate(.payInvoice(address: address, amount: amount, memo: memo)))
        default:
            return .none
        }
    }

    func handleMarkOutgoingFailed(id: String, channel: String, state: inout State) -> Effect<Action> {
        let failedId = id.hasPrefix("failed-") ? id : "failed-\(id)"
        return updateOutgoingDelivery(state: &state, oldId: id, newId: failedId, channel: channel)
    }

    func directMessageReducer() -> Reduce<State, Action> {
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                return handleTabSelected(tab, state: &state)
            case .newDmTapped, .newDmConversation(.presented(.dismiss)), .newDmConversation(.presented(.contactSaved)):
                return handleNewDmModalAction(action, state: &state)
            case .dmBackTapped:
                let previous = state.composerKey
                state.selectedDmContact = nil
                state.messages = []
                state.moveComposer(from: previous)
                return .none
            case let .dmContactSelected(contact):
                return handleDmContactSelected(contact, state: &state)
            case let .dmContactsLoaded(contacts, convos):
                state.dmContacts = contacts
                state.dmConversations = convos
                return .none
            case .sharePubkeyTapped, .sharePubkeyConfirmed, .sharePubkeyCancelled, .dmKeypairMinted, .pubkeyGenerated:
                return handlePubkeyAction(action, state: &state)
            case let .dmMessageReceived(contactId, message):
                return handleDmMessageReceived(contactId: contactId, message: message, state: &state)
            default:
                return .none
            }
        }
    }

    func handleNewDmModalAction(_ action: Action, state: inout State) -> Effect<Action> {
        switch action {
        case .newDmTapped:
            var dmState = NewDmConversation.State()
            dmState.myPublicKey = userStoredPreferences.dmPublicKey() ?? ""
            dmState.mySecretKey = userStoredPreferences.dmSecretKey() ?? ""
            state.newDmConversation = dmState
            return .none
        case .newDmConversation(.presented(.dismiss)):
            state.newDmConversation = nil
            return loadDmContactsEffect()
        case let .newDmConversation(.presented(.contactSaved(contact))):
            if (userStoredPreferences.dmSecretKey() ?? "").isEmpty, !contact.mySecretB58.isEmpty {
                userStoredPreferences.setDmSecretKey(contact.mySecretB58)
                userStoredPreferences.setDmPublicKey(contact.myPublicB58)
            }
            return .none
        default:
            return .none
        }
    }

    func handleBootstrapMessages(_ messages: [State.Message], state: inout State) -> Effect<Action> {
        state.dagSyncCount = messages.count
        for msg in messages {
            state.channelMessages[msg.channel, default: []].append(msg)
        }
        if let selected = state.selectedChannel {
            state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[selected.name] ?? [])
        }
        ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
        return .none
    }

    func handleTabSelected(_ tab: State.ChatTab, state: inout State) -> Effect<Action> {
        let previous = state.composerKey
        state.selectedTab = tab
        state.moveComposer(from: previous)
        return tab == .direct ? loadDmContactsEffect() : .none
    }

    func handleDmContactSelected(_ contact: DmContact, state: inout State) -> Effect<Action> {
        let previous = state.composerKey
        state.selectedDmContact = contact
        state.moveComposer(from: previous)
        state.messages = IdentifiedArrayOf(uniqueElements: state.dmMessages[contact.id] ?? [])
        return .run { _ in await DarkircCryptoStore.shared.clearUnread(contactId: contact.id) }
    }

    func loadDmContactsEffect() -> Effect<Action> {
        .run { send in
            let contacts = await DarkircCryptoStore.shared.allContacts()
            let convos = await DarkircCryptoStore.shared.allConversations()
            await send(.dmContactsLoaded(contacts, convos))
        }
    }

    func handlePubkeyAction(_ action: Action, state: inout State) -> Effect<Action> {
        switch action {
        case .sharePubkeyTapped:
            state.showSharePubkeyWarning = true
            return .none
        case .sharePubkeyConfirmed:
            return handleSharePubkeyConfirmed(state: &state)
        case let .dmKeypairMinted(secret, publicKey):
            guard !publicKey.isEmpty else { return .none }
            userStoredPreferences.setDmSecretKey(secret)
            userStoredPreferences.setDmPublicKey(publicKey)
            return .send(.pubkeyGenerated(publicKey))
        case .sharePubkeyCancelled:
            state.showSharePubkeyWarning = false
            return .none
        case let .pubkeyGenerated(publicKey):
            state.myDmPublicKey = publicKey
            let shareText = NighthawkContacts.contactInviteUri(
                NighthawkContact(
                    id: publicKey,
                    nickname: "",
                    dmPublicKey: publicKey,
                    ratchetCapable: true
                )
            ) ?? DarkircDmPubkeyParser.formatForSharing(publicKey)
            UIPasteboard.general.setItems(
                [[UIPasteboard.typeAutomatic: shareText]],
                options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(60)]
            )
            return .none
        default:
            return .none
        }
    }

    func handleScenePhase(_ phase: ScenePhase, state: inout State) -> Effect<Action> {
        guard phase == .active else { return .none }
        let ffiStatus = darkircStatus()
        let daemonDead = (ffiStatus == "not_running" || ffiStatus == "failed")
        let uiDisconnected = (state.connectionState == .disconnected || state.connectionState == .error)
        guard daemonDead || uiDisconnected else { return .none }
        restoreChatHistoryIfEmpty(&state)
        if !uiDisconnected {
            state.connectionState = .disconnected
        }
        return .send(.connectTapped)
    }

    func handleWalletRequest(amount: String, memo: String, state: inout State) -> Effect<Action> {
        let address = state.receiveAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else {
            state.diagnosticDetail = "Wallet address is not ready yet."
            return .none
        }
        let amountText = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let memoText = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        state.composedMessage = PaymentRequestUri.build(
            address: address,
            amount: amountText.isEmpty ? nil : amountText,
            memo: memoText.isEmpty ? nil : memoText
        )
        return .send(.sendMessage)
    }

    func handleWalletSend(
        address: String,
        amount: String,
        memo: String,
        tip: Bool,
        state: inout State
    ) -> Effect<Action> {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            state.diagnosticDetail = "Enter a wallet address to pay."
            return .none
        }
        let amountText = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let typedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let memoText: String? = typedMemo.isEmpty ? (tip ? "Tip" : nil) : typedMemo
        let targetChannel: String? = state.selectedTab == .direct
            ? state.selectedDmContact?.contactLabel
            : state.selectedChannel?.name
        let receipt = ChatReceipt(
            id: UUID().uuidString,
            phase: .pending,
            amount: amountText.isEmpty ? "0" : amountText,
            address: trimmedAddress,
            memo: memoText
        )
        ChatReceiptBook.stage(receipt, targetChannel: targetChannel)
        return .send(.delegate(.payInvoice(
            address: trimmedAddress,
            amount: amountText.isEmpty ? nil : amountText,
            memo: memoText
        )))
    }

    func handleOpenNotifiedThread(_ thread: String, state: inout State) -> Effect<Action> {
        let key = thread.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return .none }
        if key.hasPrefix("#") {
            let channel = state.channels.first {
                $0.name.caseInsensitiveCompare(key) == .orderedSame
            } ?? State.Channel(name: key)
            if state.channels[id: channel.id] == nil {
                state.channels.append(channel)
            }
            return .merge(.send(.tabSelected(.channels)), .send(.channelSelected(channel)))
        }
        if let contact = state.dmContacts.first(where: {
            $0.contactLabel.caseInsensitiveCompare(key) == .orderedSame || $0.id == key
        }) {
            return .merge(.send(.tabSelected(.direct)), .send(.dmContactSelected(contact)))
        }
        return .send(.tabSelected(.direct))
    }

    func handleSharePubkeyConfirmed(state: inout State) -> Effect<Action> {
        state.showSharePubkeyWarning = false
        if let existing = userStoredPreferences.dmPublicKey()?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !existing.isEmpty {
            return .send(.pubkeyGenerated(existing))
        }
        return .run { send in
            if let keypair = DarkircContactManager.generateKeypair() {
                await send(.dmKeypairMinted(secret: keypair.secretB58, publicKey: keypair.publicB58))
            }
        }
    }
}
