//
//  Chat+Helpers.swift
//  Home
//
//  History restoration, outgoing delivery tracking, and E2E DM sending/decryption helpers.
//

import ComposableArchitecture
import DarkfiCore
import Foundation
import Models

func restoreChatHistoryIfEmpty(_ state: inout Chat.State) {
    guard state.channelMessages.isEmpty && state.dmMessages.isEmpty else { return }
    let loaded = ChatHistoryStore.load()
    state.channelMessages = loaded.channels
    state.dmMessages = loaded.dms
    state.seenEventIds.formUnion(loaded.ids)
    if state.selectedTab == .channels, let name = state.selectedChannel?.name {
        state.messages = IdentifiedArrayOf(uniqueElements: state.channelMessages[name] ?? [])
    }
}

func isChatDeliveryId(_ id: String) -> Bool {
    if UUID(uuidString: id) != nil { return true }
    return id.hasPrefix("queued-") || id.hasPrefix("local-") || id.hasPrefix("failed-")
}

func updateOutgoingDelivery(
    state: inout Chat.State,
    oldId: String,
    newId: String,
    channel: String
) -> Effect<Chat.Action> {
    var didChange = false
    if var bucket = state.channelMessages[channel],
       let idx = bucket.firstIndex(where: { $0.id == oldId }) {
        let old = bucket[idx]
        let updated = Chat.State.Message(
            id: newId,
            sender: old.sender,
            content: old.content,
            channel: old.channel,
            timestamp: old.timestamp,
            isOutgoing: true,
            failedToDecrypt: old.failedToDecrypt
        )
        bucket[idx] = updated
        state.channelMessages[channel] = bucket
        didChange = true
        if state.selectedTab == .channels && state.selectedChannel?.name == channel,
           let msgIdx = state.messages.index(id: oldId) {
            state.messages[msgIdx] = updated
        }
    }
    if let contact = state.dmContacts.first(where: {
        $0.contactLabel.caseInsensitiveCompare(channel) == .orderedSame
    }), var bucket = state.dmMessages[contact.id],
       let idx = bucket.firstIndex(where: { $0.id == oldId }) {
        let old = bucket[idx]
        let updated = Chat.State.Message(
            id: newId,
            sender: old.sender,
            content: old.content,
            channel: old.channel,
            timestamp: old.timestamp,
            isOutgoing: true,
            failedToDecrypt: old.failedToDecrypt
        )
        bucket[idx] = updated
        state.dmMessages[contact.id] = bucket
        didChange = true
        if state.selectedTab == .direct && state.selectedDmContact?.id == contact.id,
           let msgIdx = state.messages.index(id: oldId) {
            state.messages[msgIdx] = updated
        }
    }
    guard didChange else { return .none }
    state.seenEventIds.remove(oldId)
    state.seenEventIds.insert(newId)
    ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)
    return .none
}

/// Register the contact's ChaCha keys with Rust and PRIVMSG the contact label.
/// Rust handles ChaChaBox encryption on the wire; public `selectedChannel` (#dev) is not a fallback.
func sendDirectMessage(
    state: inout Chat.State,
    text: String,
    targetContact: DmContact? = nil
) -> Effect<Chat.Action> {
    guard let contact = targetContact ?? state.selectedDmContact else { return .none }
    if targetContact == nil {
        state.composerDrafts.removeValue(forKey: state.composerKey)
        state.composedMessage = ""
    }

    if targetContact == nil && text.hasPrefix("/") {
        return handleDirectSlash(state: &state, contact: contact, text: text)
    }

    let offline = !state.connectionState.isConnected
    let message = Chat.State.Message(
        id: offline ? "queued-\(UUID().uuidString)" : "local-\(UUID().uuidString)",
        sender: state.nickname,
        content: text,
        channel: contact.contactLabel,
        isOutgoing: true
    )
    state.dmMessages[contact.id, default: []].append(message)
    if state.selectedTab == .direct && state.selectedDmContact?.id == contact.id {
        state.messages.append(message)
    }
    state.seenEventIds.insert(message.id)
    ChatHistoryStore.save(channels: state.channelMessages, dms: state.dmMessages)

    let secret = contact.mySecretB58
    let theirPublic = contact.theirPublicB58
    let label = contact.contactLabel
    let ratchetCapable = contact.ratchetCapable
    let nick = state.nickname
    let contactId = contact.id
    let optimisticId = message.id
    if offline {
        return .run { _ in
            _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: label, text: text)
        }
    }

    return .run { send in
        do {
            try sendChatMessage(channel: label, nick: nick, message: text)
            await DarkircCryptoStore.shared.updateConversation(
                contactId: contactId,
                lastMessage: text,
                incrementUnread: false
            )
        } catch {
            let msg = error.localizedDescription.lowercased()
            let needsRegister = msg.contains("not registered") || msg.contains("unregistered")
                || msg.contains("unknown contact") || msg.contains("unknown dm")
            if needsRegister,
               let skBytes = Base58.decode(secret), skBytes.count == 32,
               let pkBytes = Base58.decode(theirPublic), pkBytes.count == 32 {
                do {
                    try registerDmContactEx(
                        nick: label,
                        mySecret: skBytes,
                        theirPublic: pkBytes,
                        ratchetCapable: ratchetCapable
                    )
                    try sendChatMessage(channel: label, nick: nick, message: text)
                    await DarkircCryptoStore.shared.updateConversation(
                        contactId: contactId,
                        lastMessage: text,
                        incrementUnread: false
                    )
                    return
                } catch {}
            }
            _ = await ChatOutboxStore.shared.enqueue(id: optimisticId, channel: label, text: text)
            await send(.ircBridgeError("Send failed; queued for retry: \(error.localizedDescription)"))
            await send(.markOutgoingFailed(id: optimisticId, channel: label))
        }
    }
}

private func handleDirectSlash(
    state: inout Chat.State,
    contact: DmContact,
    text: String
) -> Effect<Chat.Action> {
    let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
    let cmd = parts.first?.lowercased() ?? ""
    let arg = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

    func local(_ content: String) {
        let sys = Chat.State.Message(
            sender: "System",
            content: content,
            channel: contact.contactLabel,
            isOutgoing: false
        )
        state.dmMessages[contact.id, default: []].append(sys)
        state.messages.append(sys)
    }

    switch cmd {
    case "/clear":
        state.dmMessages[contact.id] = []
        state.messages = []
        return .none
    case "/help":
        local("DM commands: /me <action>, /clear, /help. Messages are encrypted to \(contact.contactLabel).")
        return .none
    case "/me":
        guard !arg.isEmpty else {
            local("Usage: /me <action>")
            return .none
        }
        return sendDirectMessage(state: &state, text: "* \(state.nickname) \(arg)")
    default:
        local("Command \(cmd) stays on public channels. This DM is encrypted to \(contact.contactLabel).")
        return .none
    }
}

func deliverDirectMessage(
    send: Send<Chat.Action>,
    message: Chat.State.Message,
    viewingContactId: String?
) async {
    let contacts = await DarkircCryptoStore.shared.allContacts()
    let labeled = contacts.first {
        $0.contactLabel.compare(message.channel, options: .caseInsensitive) == .orderedSame
    }
    if let labeled {
        let plain = DarkircContactManager.decryptMessage(
            mySecretB58: labeled.mySecretB58,
            theirPublicB58: labeled.theirPublicB58,
            ciphertextB58: message.content
        )
        let decoded = Chat.State.Message(
            id: message.id,
            sender: message.sender,
            content: plain ?? message.content,
            channel: labeled.contactLabel,
            timestamp: message.timestamp,
            isOutgoing: message.isOutgoing,
            failedToDecrypt: false
        )
        let unread = !message.isOutgoing && viewingContactId != labeled.id
        await DarkircCryptoStore.shared.updateConversation(
            contactId: labeled.id,
            lastMessage: decoded.content,
            at: message.timestamp,
            incrementUnread: unread
        )
        await send(.dmMessageReceived(labeled.id, decoded))
        return
    }
    if let any = DarkircContactManager.tryDecryptWithAnyContact(
        ciphertextB58: message.content,
        contacts: contacts
    ) {
        let decoded = Chat.State.Message(
            id: message.id,
            sender: message.sender,
            content: any.plaintext,
            channel: any.contact.contactLabel,
            timestamp: message.timestamp,
            isOutgoing: message.isOutgoing
        )
        let unread = !message.isOutgoing && viewingContactId != any.contact.id
        await DarkircCryptoStore.shared.updateConversation(
            contactId: any.contact.id,
            lastMessage: any.plaintext,
            at: message.timestamp,
            incrementUnread: unread
        )
        await send(.dmMessageReceived(any.contact.id, decoded))
    }
}
