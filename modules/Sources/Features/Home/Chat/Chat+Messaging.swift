//
//  Chat+Messaging.swift
//  Home
//
//  Public channel sending, slash commands, incoming message handling, and payment receipts for Chat.
//

import ComposableArchitecture
import DarkfiCore
import Foundation
import Models
import UIKit

extension Chat {
    func handleSendMessage(state: inout State) -> Effect<Action> {
        let text = state.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .none }
        // Direct tab always uses the open DM. Never fall through to #dev.
        if state.selectedTab == .direct {
            return sendDirectMessage(state: &state, text: text)
        }
        guard let channel = state.selectedChannel else { return .none }

        state.composerDrafts.removeValue(forKey: state.composerKey)
        state.composedMessage = ""

        if text.hasPrefix("/") {
            return handleChannelSlashCommand(text: text, channel: channel, state: &state)
        }

        let offline = !state.connectionState.isConnected
        let message = State.Message(
            id: offline ? "queued-\(UUID().uuidString)" : "local-\(UUID().uuidString)",
            sender: state.nickname,
            content: text,
            channel: channel.name,
            isOutgoing: true
        )
        state.messages.append(message)
        state.channelMessages[channel.name, default: []].append(message)
        state.seenEventIds.insert(message.id)
        ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)

        let channelTarget = channel.name
        let nick = state.nickname
        let optimisticId = message.id
        if offline {
            return .run { send in
                _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: channelTarget, text: text)
                await send(.ircBridgeError("Queued offline — will send when DarkIRC reconnects"))
            }
        }
        return .run { send in
            do {
                try sendChatMessage(channel: channelTarget, nick: nick, message: text)
            } catch {
                _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: channelTarget, text: text)
                await send(.ircBridgeError("Send failed; queued for retry: \(error.localizedDescription)"))
                await send(.markOutgoingFailed(id: optimisticId, channel: channelTarget))
            }
        }
    }

    private func appendSystemMessage(_ content: String, to targetChannel: String, state: inout State) {
        let sysMsg = State.Message(
            id: UUID().uuidString,
            sender: "System",
            content: content,
            channel: targetChannel,
            timestamp: Date(),
            isOutgoing: false
        )
        state.messages.append(sysMsg)
        state.channelMessages[targetChannel, default: []].append(sysMsg)
    }

    private func handleChannelSlashCommand(
        text: String,
        channel: State.Channel,
        state: inout State
    ) -> Effect<Action> {
        let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let cmd = parts.first?.lowercased() ?? ""
        let arg = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

        switch cmd {
        case "/nick":
            return handleSlashNick(arg: arg, channelName: channel.name, state: &state)
        case "/join":
            return handleSlashJoin(arg: arg, channelName: channel.name, state: &state)
        case "/part", "/leave":
            return handleSlashPart(channel: channel, state: &state)
        case "/clear":
            state.channelMessages[channel.name] = []
            state.messages = []
            return .none
        case "/me":
            return handleSlashMe(arg: arg, channelName: channel.name, state: &state)
        case "/msg":
            return handleSlashMsg(arg: arg, channelName: channel.name, state: &state)
        case "/help":
            let helpText = [
                "Available DarkIRC commands:",
                "  /nick <name> — Change nickname (1–24 characters)",
                "  /join <#channel> — Join or switch to channel",
                "  /part — Leave current channel",
                "  /clear — Clear messages in current view",
                "  /me <action> — Send action message (* nick action)",
                "  /msg <target> <text> — Send message to channel or nick",
                "  /help — Show this help message"
            ].joined(separator: "\n")
            appendSystemMessage(helpText, to: channel.name, state: &state)
            return .none
        default:
            appendSystemMessage("Unknown command '\(cmd)'. Type /help for DarkIRC commands.", to: channel.name, state: &state)
            return .none
        }
    }

    private func handleSlashNick(arg: String, channelName: String, state: inout State) -> Effect<Action> {
        guard !arg.isEmpty && arg.count <= DarkfiChatDefaults.maxNickLen else {
            appendSystemMessage(
                "Invalid nickname. Usage: /nick <name> (1–24 alphanumeric/underscore characters)",
                to: channelName,
                state: &state
            )
            return .none
        }
        let sanitized = DarkfiChatDefaults.sanitizeNickname(arg)
        state.nickname = sanitized
        DarkfiChatDefaults.setNickname(sanitized)
        appendSystemMessage("Your nickname is now: \(sanitized)", to: channelName, state: &state)
        return .none
    }

    private func handleSlashJoin(arg: String, channelName: String, state: inout State) -> Effect<Action> {
        guard !arg.isEmpty else {
            appendSystemMessage("Usage: /join <#channel>", to: channelName, state: &state)
            return .none
        }
        let previous = state.composerKey
        let targetChan = arg.hasPrefix("#") ? arg : "#\(arg)"
        if state.channels[id: targetChan] == nil {
            state.channels.append(State.Channel(name: targetChan))
        }
        if let joined = state.channels[id: targetChan] {
            state.selectedChannel = joined
            state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[joined.name] ?? [])
        }
        state.moveComposer(from: previous)
        appendSystemMessage("Joined channel: \(targetChan)", to: targetChan, state: &state)
        return .none
    }

    private func handleSlashPart(channel: State.Channel, state: inout State) -> Effect<Action> {
        let previous = state.composerKey
        let targetChan = channel.name
        state.channels.remove(id: targetChan)
        state.channelMessages.removeValue(forKey: targetChan)
        state.composerDrafts.removeValue(forKey: "ch:\(channel.id)")
        if let first = state.channels.first {
            state.selectedChannel = first
            state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[first.name] ?? [])
        } else {
            state.selectedChannel = nil
            state.messages = []
        }
        state.moveComposer(from: previous)
        return .none
    }

    private func handleSlashMe(arg: String, channelName: String, state: inout State) -> Effect<Action> {
        guard !arg.isEmpty else {
            appendSystemMessage("Usage: /me <action>", to: channelName, state: &state)
            return .none
        }
        let actionText = "* \(state.nickname) \(arg)"
        let message = State.Message(
            sender: state.nickname,
            content: actionText,
            channel: channelName,
            isOutgoing: true
        )
        state.messages.append(message)
        state.channelMessages[channelName, default: []].append(message)
        state.seenEventIds.insert(message.id)
        let nick = state.nickname
        let optimisticId = message.id
        return .run { send in
            do {
                try sendChatMessage(channel: channelName, nick: nick, message: actionText)
            } catch {
                await send(.ircBridgeError("Send failed: \(error.localizedDescription)"))
                await send(.removeOptimisticMessage(id: optimisticId, channel: channelName))
            }
        }
    }

    private func handleSlashMsg(arg: String, channelName: String, state: inout State) -> Effect<Action> {
        let msgParts = arg.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard msgParts.count == 2 else {
            appendSystemMessage("Usage: /msg <target> <message>", to: channelName, state: &state)
            return .none
        }
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

    func handleMessageReceived(_ message: State.Message, state: inout State) -> Effect<Action> {
        guard !state.seenEventIds.contains(message.id) else {
            return .none
        }
        state.seenEventIds.insert(message.id)

        if !message.channel.hasPrefix("#") {
            let viewingContactId = state.selectedTab == .direct ? state.selectedDmContact?.id : nil
            return .run { send in
                await deliverDirectMessage(
                    send: send,
                    message: message,
                    viewingContactId: viewingContactId
                )
            }
        }

        if state.seenEventIds.count > 10_000 {
            state.seenEventIds = []
        }

        let isOptimisticLocal: (State.Message) -> Bool = { local in
            local.isOutgoing &&
                local.sender == message.sender &&
                local.content == message.content &&
                local.id != message.id &&
                isChatDeliveryId(local.id)
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
        ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
        ChatNotificationRouter.maybeNotify(
            ChatNotificationRouter.NotificationEvent(
                nick: message.sender,
                body: message.content,
                thread: message.channel,
                isOutgoing: message.isOutgoing,
                timestamp: message.timestamp,
                ownNick: state.nickname
            )
        )
        return .none
    }

    func handlePostBroadcastedReceipt(_ receipt: ChatReceipt, channel: String?, state: inout State) -> Effect<Action> {
        let encoded = ChatReceiptCodec.encode(receipt)
        let target = channel?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let target, !target.isEmpty, !target.hasPrefix("#"),
           let contact = state.dmContacts.first(where: {
               $0.contactLabel.caseInsensitiveCompare(target) == .orderedSame
           }) {
            return sendDirectMessage(state: &state, text: encoded, targetContact: contact)
        }
        let targetChannel = (target?.isEmpty == false ? target : nil) ?? state.selectedChannel?.name
        guard let channelName = targetChannel, !channelName.isEmpty else { return .none }
        let offline = !state.connectionState.isConnected
        let message = State.Message(
            id: offline ? "queued-\(UUID().uuidString)" : "local-\(UUID().uuidString)",
            sender: state.nickname,
            content: encoded,
            channel: channelName,
            isOutgoing: true
        )
        state.channelMessages[channelName, default: []].append(message)
        if state.selectedTab == .channels && state.selectedChannel?.name == channelName {
            state.messages.append(message)
        }
        state.seenEventIds.insert(message.id)
        ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
        let nick = state.nickname
        let optimisticId = message.id
        if offline {
            return .run { _ in
                _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: channelName, text: encoded)
            }
        }
        return .run { send in
            do {
                try sendChatMessage(channel: channelName, nick: nick, message: encoded)
            } catch {
                _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: channelName, text: encoded)
                await send(.markOutgoingFailed(id: optimisticId, channel: channelName))
            }
        }
    }

    func handleRetryOutgoing(channel: String, text: String, state: inout State) -> Effect<Action> {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return .none }
        var removedIds: [String] = []
        if var bucket = state.channelMessages[channel] {
            for msg in bucket where msg.id.hasPrefix("failed-") && msg.content == body {
                removedIds.append(msg.id)
            }
            bucket.removeAll { msg in removedIds.contains(msg.id) }
            state.channelMessages[channel] = bucket
        }
        if let contact = state.dmContacts.first(where: {
            $0.contactLabel.caseInsensitiveCompare(channel) == .orderedSame
        }), var bucket = state.dmMessages[contact.id] {
            for msg in bucket where msg.id.hasPrefix("failed-") && msg.content == body {
                removedIds.append(msg.id)
            }
            bucket.removeAll { msg in removedIds.contains(msg.id) }
            state.dmMessages[contact.id] = bucket
        }
        for rid in removedIds {
            state.messages.remove(id: rid)
            state.seenEventIds.remove(rid)
        }
        if !removedIds.isEmpty {
            ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
        }
        let outboxIdsToClear = removedIds.map { id in
            id.hasPrefix("failed-") ? String(id.dropFirst("failed-".count)) : id
        }
        state.composedMessage = body
        return .merge(
            .run { _ in
                for oid in outboxIdsToClear {
                    await ChatOutboxStore.shared.remove(id: oid)
                }
            },
            .send(.sendMessage)
        )
    }

    func handleDmMessageReceived(contactId: String, message: State.Message, state: inout State) -> Effect<Action> {
        if state.dmMessages[contactId]?.contains(where: { $0.id == message.id }) == true {
            return .none
        }
        let isOptimisticLocal: (State.Message) -> Bool = { local in
            local.isOutgoing &&
                local.sender == message.sender &&
                local.content == message.content &&
                local.id != message.id &&
                isChatDeliveryId(local.id)
        }
        state.dmMessages[contactId, default: []].removeAll(where: isOptimisticLocal)
        state.dmMessages[contactId, default: []].append(message)
        let viewing = state.selectedTab == .direct && state.selectedDmContact?.id == contactId
        if viewing {
            state.messages.removeAll(where: isOptimisticLocal)
            state.messages.append(message)
        }
        if let idx = state.dmConversations.firstIndex(where: { $0.id == contactId }) {
            state.dmConversations[idx].lastMessageText = message.content
            state.dmConversations[idx].lastMessageAt = message.timestamp
            if !viewing && !message.isOutgoing {
                state.dmConversations[idx].unreadCount += 1
            }
        }
        ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
        ChatNotificationRouter.maybeNotify(
            ChatNotificationRouter.NotificationEvent(
                nick: message.sender,
                body: message.content,
                thread: message.channel.isEmpty ? contactId : message.channel,
                isOutgoing: message.isOutgoing,
                timestamp: message.timestamp,
                ownNick: state.nickname
            )
        )
        return .none
    }
}
