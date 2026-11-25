//
//  ChatView+Sections.swift
//  Home
//
//  Connected channels, DM contacts, message list, compose bar, and pay sheet for ChatView.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents
import UIKit

// MARK: - Connected State & Channels
extension ChatView {
    var connectedView: some View {
        VStack(spacing: 0) {
            switch store.selectedTab {
            case .channels:
                VStack(spacing: 0) {
                    channelBar
                    Text(L10n.Nighthawk.Chat.publicPlaintextBadge)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    messagesList
                    composeBar
                }
            case .direct:
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
        .alert(L10n.Nighthawk.Chat.sharePubkeyTitle, isPresented: $store.showSharePubkeyWarning) {
            Button(L10n.Nighthawk.Chat.sharePubkeyCopy, action: { store.send(.sharePubkeyConfirmed) })
            Button(L10n.General.cancel, role: .cancel, action: { store.send(.sharePubkeyCancelled) })
        } message: {
            Text(L10n.Nighthawk.Chat.sharePubkeyMessage)
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
}

// MARK: - DM Contacts & Header
extension ChatView {
    var dmContactsList: some View {
        VStack(spacing: 0) {
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

            if let myKey = store.myDmPublicKey {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Nighthawk.Chat.myPublicKeyCopied)
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

            if store.dmContacts.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.4))

                    Text(L10n.Nighthawk.Chat.noDmContactsTitle)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

                    Text(L10n.Nighthawk.Chat.noDmContactsBody)
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

    var dmConversationHeader: some View {
        HStack(spacing: 8) {
            Button(action: { store.send(.dmBackTapped) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L10n.General.back)

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
                    Text(L10n.Nighthawk.Chat.e2eEncrypted)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 11))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.7))
                    if let card = NighthawkContactStore.findByNick(contact.contactLabel) {
                        Text(NighthawkContacts.safetyNumber(dmPublicKey: card.dmPublicKey, walletAddress: card.walletAddress))
                            .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 9))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.8))
                            .lineLimit(2)
                    }
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
}

// MARK: - Messages, Compose Bar & Pay Sheet
extension ChatView {
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
                .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        } else {
            messageContent(message)
        }
    }

    func messageContent(_ message: Chat.State.Message) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: 6) {
                Text("<\(message.sender)>")
                    .font(.custom(FontFamily.DejaVuSansMono.bold.name, size: 13))
                    .foregroundColor(
                        message.isOutgoing
                            ? Asset.Colors.Nighthawk.peach.color
                            : Asset.Colors.Nighthawk.parmaviolet.color
                    )
                Text(message.content)
                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(message.timestamp, style: .time)
                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.6))
            }
            .textSelection(.enabled)
            .contextMenu {
                Button {
                    UIPasteboard.general.setItems(
                        [[UIPasteboard.typeAutomatic: message.content]],
                        options: [
                            .localOnly: true,
                            .expirationDate: Date().addingTimeInterval(60)
                        ]
                    )
                } label: {
                    Label(L10n.Nighthawk.Chat.copyMessage, systemImage: "doc.on.doc")
                }
            }

            if let offer = FudUri.find(in: message.content) {
                Button(L10n.Nighthawk.Chat.queueFile(offer.displayName)) {
                    store.send(.fudOfferTapped(offer.raw, meshOn: mesh.enabled))
                }
                .font(.custom(FontFamily.DejaVuSansMono.bold.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                .padding(.leading, 12)
                .padding(.vertical, 2)
            }

            if let invoice = PaymentRequestUri.find(in: message.content) {
                invoiceCard(invoice)
            }

            if let receipt = ChatReceiptCodec.parse(message.content) {
                receiptCard(ChatReceiptBook.lookup(id: receipt.id) ?? receipt)
            }

            if let link = ChatLinkGuard.firstClearnet(in: message.content) {
                Button(L10n.Nighthawk.Chat.link) { clearnetURL = link }
                    .font(.custom(FontFamily.DejaVuSansMono.bold.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            }

            if let delivery = ChatDeliveryLabel.from(eventId: message.id, isOutgoing: message.isOutgoing) {
                HStack(spacing: 8) {
                    Text(delivery.rawValue)
                        .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    if delivery == .failed {
                        Button(L10n.Nighthawk.Chat.retry) {
                            store.send(.retryOutgoing(channel: message.channel, text: message.content))
                        }
                        .font(.custom(FontFamily.DejaVuSansMono.bold.name, size: 11))
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }

    func invoiceCard(_ invoice: PaymentRequestUri.Parsed) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.Nighthawk.Chat.paymentRequest)
                .font(.custom(FontFamily.DejaVuSansMono.bold.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            if let amount = invoice.amount, !amount.isEmpty {
                Text("\(amount) DRK")
                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
            }
            Text(invoice.address)
                .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .lineLimit(1)
                .truncationMode(.middle)
            if let memo = invoice.memo, !memo.isEmpty {
                Text(memo)
                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(2)
            }
            Button(L10n.Nighthawk.Chat.pay) {
                store.send(
                    .payInvoiceTapped(
                        address: invoice.address,
                        amount: invoice.amount,
                        memo: invoice.memo
                    )
                )
            }
            .font(.custom(FontFamily.DejaVuSansMono.bold.name, size: 12))
            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Asset.Colors.Nighthawk.navy.color.opacity(0.55))
        .padding(.leading, 4)
        .padding(.vertical, 2)
    }

    func receiptCard(_ live: ChatReceipt) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.Nighthawk.Chat.paymentPhase(live.phase.rawValue))
                .font(.custom(FontFamily.DejaVuSansMono.bold.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            Text("\(live.amount) DRK → \(live.address)")
                .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                .lineLimit(1)
                .truncationMode(.middle)
            if let tx = live.txId, !tx.isEmpty {
                Text(tx)
                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Asset.Colors.Nighthawk.navy.color.opacity(0.55))
    }

    var composeBar: some View {
        let canSend = !store.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(spacing: 12) {
            Button {
                payAddress = NighthawkContactStore.findByNick(store.selectedDmContact?.contactLabel ?? "")?.walletAddress ?? ""
                showPaySheet = true
            } label: {
                Image(systemName: "banknote")
                    .font(.system(size: 22))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            }
            .accessibilityLabel(L10n.Nighthawk.Chat.sendOrRequestDrk)
            TextField(L10n.Nighthawk.Chat.messagePlaceholder, text: $store.composedMessage)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 15))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
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

    var paySheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextField(L10n.Nighthawk.Chat.amountDrkPlaceholder, text: $payAmount)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.Nighthawk.RequestMoney.memo, text: $payMemo)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.Nighthawk.Chat.payToAddressPlaceholder, text: $payAddress)
                    .textFieldStyle(.roundedBorder)
                Button(L10n.Nighthawk.WalletTab.actionRequest) {
                    showPaySheet = false
                    store.send(.walletRequest(amount: payAmount, memo: payMemo))
                }
                Button(L10n.General.send) {
                    showPaySheet = false
                    store.send(.walletSend(address: payAddress, amount: payAmount, memo: payMemo, tip: false))
                }
                Button(L10n.Nighthawk.Chat.tip) {
                    showPaySheet = false
                    store.send(.walletSend(address: payAddress, amount: payAmount, memo: payMemo, tip: true))
                }
                Spacer()
            }
            .padding(16)
            .navigationTitle(L10n.Nighthawk.WalletTab.drk)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.close) { showPaySheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
