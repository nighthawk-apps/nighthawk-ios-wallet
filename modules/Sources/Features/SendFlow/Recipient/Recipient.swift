//
//  Recipient.swift
//
//
//  Created by Matthew watt on 7/23/23.
//

import ComposableArchitecture
import Generated
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
        public var showScanButton: Bool {
            @Dependency(\.processInfo) var processInfo
            return !processInfo.isiOSAppOnMac()
        }

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
        case scanQRCodeTapped

        public enum Delegate: Equatable {
            case goBack
            case proceedWithRecipient(String)
            case scanCode
        }
    }

    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.pasteboard) var pasteboard

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .send(.delegate(.goBack))
            case .clearRecipientTapped:
                state.recipient = ""
                return .none
            case .continueTapped:
                return .send(.delegate(.proceedWithRecipient(state.recipient)))
            case .delegate:
                return .none
            case .onAppear:
                if let contents = pasteboard.getString() {
                    state.pasteboardContainsDarkFiAddress = derivationTool.isDarkFiAddress(contents.data, "testnet")
                }
                return .none
            case .pasteFromClipboardTapped:
                guard let contents = pasteboard.getString(),
                      derivationTool.isDarkFiAddress(contents.data, "testnet") else { return .none }
                return .send(.recipientInputChanged(contents.data))
            case let .recipientInputChanged(recipient):
                state.recipient = recipient
                // DarkFi: no TEX address concept — all addresses are private
                state.isRecipientValid = derivationTool.isDarkFiAddress(recipient, "testnet")
                return .none
            case .scanQRCodeTapped:
                return .send(.delegate(.scanCode))
            }
        }
    }

    public init() {}
}
