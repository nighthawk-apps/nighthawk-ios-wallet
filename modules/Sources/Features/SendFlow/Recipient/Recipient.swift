//
//  Recipient.swift
//
//
//  Created by Matthew watt on 7/23/23.
//

import ComposableArchitecture
import Generated
import Models
import Pasteboard
import ProcessInfoClient
import SwiftUI
import UIComponents
import Utils

@Reducer
public struct Recipient {
    @ObservableState
    public struct State: Equatable {
        public var recipient = ""
        public var hasEnteredRecipient: Bool { recipient.isEmpty == false }
        public var pasteboardContainsDarkFiAddress = false
        public var canPasteAddress: Bool { pasteboardContainsDarkFiAddress && !hasEnteredRecipient }
        public var specificValidationError: NighthawkTextFieldValidationState?
        public var isRecipientValid = false
        public var showScanButton = true
        public var addressBook: [DeviceAddressBook.Entry] = []
        public var saveLabel = ""
        /// Amount and memo carried by a pasted or typed `drk:` invoice.
        public var invoiceAmount: String?
        public var invoiceMemo: String?

        public init() {}
    }

    public enum Action: Equatable {
        case backButtonTapped
        case clearRecipientTapped
        case continueTapped
        case delegate(Delegate)
        case onAppear
        case pasteFromClipboardTapped
        case recipientInputChanged(String)
        case addressBookLoaded([DeviceAddressBook.Entry])
        case addressBookEntryTapped(DeviceAddressBook.Entry)
        case saveLabelChanged(String)
        case saveAddressTapped
        case scanQRCodeTapped

        public enum Delegate: Equatable {
            case goBack
            case proceedWithRecipient(String, amount: String?, memo: String?)
            case scanCode
        }
    }

    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.processInfo) var processInfo

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .send(.delegate(.goBack))
            case .clearRecipientTapped:
                state.recipient = ""
                return .none
            case .continueTapped:
                return .send(.delegate(.proceedWithRecipient(
                    state.recipient,
                    amount: state.invoiceAmount,
                    memo: state.invoiceMemo
                )))
            case .delegate:
                return .none
            case .onAppear:
                state.showScanButton = !processInfo.isiOSAppOnMac()
                state.addressBook = DeviceAddressBook.load()
                if let contents = pasteboard.getString() {
                    let trimmed = contents.data.trimmingCharacters(in: .whitespacesAndNewlines)
                    let candidate = PaymentRequestUri.parse(trimmed)?.address ?? trimmed
                    state.pasteboardContainsDarkFiAddress = derivationTool.isDarkFiAddress(candidate, "testnet")
                }
                return .none
            case let .addressBookLoaded(entries):
                state.addressBook = entries
                return .none
            case let .addressBookEntryTapped(entry):
                return .send(.recipientInputChanged(entry.address))
            case let .saveLabelChanged(label):
                state.saveLabel = label
                return .none
            case .saveAddressTapped:
                state.addressBook = DeviceAddressBook.upsert(label: state.saveLabel, address: state.recipient)
                state.saveLabel = ""
                return .none
            case .pasteFromClipboardTapped:
                guard let contents = pasteboard.getString() else { return .none }
                let trimmed = contents.data.trimmingCharacters(in: .whitespacesAndNewlines)
                if let parsed = PaymentRequestUri.parse(trimmed), derivationTool.isDarkFiAddress(parsed.address, "testnet") {
                    state.recipient = parsed.address
                    state.invoiceAmount = parsed.amount
                    state.invoiceMemo = parsed.memo
                    state.isRecipientValid = true
                    return .none
                } else if derivationTool.isDarkFiAddress(trimmed, "testnet") {
                    state.recipient = trimmed
                    state.invoiceAmount = nil
                    state.invoiceMemo = nil
                    state.isRecipientValid = true
                    return .none
                }
                return .none
            case let .recipientInputChanged(recipient):
                let trimmed = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
                let parsed = PaymentRequestUri.parse(trimmed)
                let lower = trimmed.lowercased()
                if let parsed, lower.hasPrefix("drk:") || lower.hasPrefix("darkfi:") {
                    state.recipient = parsed.address
                    state.invoiceAmount = parsed.amount
                    state.invoiceMemo = parsed.memo
                } else {
                    let previous = state.recipient
                    state.recipient = parsed?.address ?? trimmed
                    if state.recipient != previous {
                        state.invoiceAmount = nil
                        state.invoiceMemo = nil
                    }
                }
                state.isRecipientValid = derivationTool.isDarkFiAddress(state.recipient, "testnet")
                return .none
            case .scanQRCodeTapped:
                return .send(.delegate(.scanCode))
            }
        }
    }

    public init() {}
}
