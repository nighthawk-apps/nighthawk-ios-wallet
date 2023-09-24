//
//  Recipient.swift
//  
//
//  Created by Matthew watt on 7/23/23.
//

import ComposableArchitecture
import Generated
import Pasteboard
import SwiftUI
import UIComponents
import Utils
import ZcashLightClientKit

public struct Recipient: Reducer {
    let networkType: NetworkType
    
    public struct State: Equatable {
        public var recipient = "".redacted
        public var hasEnteredRecipient: Bool { recipient.data.isEmpty == false }
        public var pasteboardContainsZAddress = false
        public var canPasteAddress: Bool { pasteboardContainsZAddress && !hasEnteredRecipient }
        public var isRecipientValid = false
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case clearRecipientTapped
        case continueTapped
        case delegate(Delegate)
        case onAppear
        case pasteFromClipboardTapped
        case recipientInputChanged(RedactableString)
        case scanQRCodeTapped
        
        public enum Delegate: Equatable {
            case goBack
            case proceedWithRecipient(RedactableString)
            case scanCode
        }
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.pasteboard) var pasteboard
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { send in await send(.delegate(.goBack)) }
            case .clearRecipientTapped:
                state.recipient = "".redacted
                return .none
            case .continueTapped:
                return .send(.delegate(.proceedWithRecipient(state.recipient)))
            case .delegate:
                return .none
            case .onAppear:
                if let contents = pasteboard.getString() {
                    state.pasteboardContainsZAddress = derivationTool.isZcashAddress(contents.data, networkType)
                }
                return .none
            case .pasteFromClipboardTapped:
                guard let contents = pasteboard.getString(),
                    derivationTool.isZcashAddress(contents.data, networkType) else { return .none }
                
                state.recipient = contents
                state.isRecipientValid = true
                return .none
            case let .recipientInputChanged(redactedRecipient):
                state.recipient = redactedRecipient
                state.isRecipientValid = derivationTool.isZcashAddress(redactedRecipient.data, networkType)
                return .none
            case .scanQRCodeTapped:
                return .send(.delegate(.scanCode))
            }
        }
    }
}

// MARK: - ViewStore
extension ViewStoreOf<Recipient> {
    func bindingForRedactableRecipient(_ recipient: RedactableString) -> Binding<String> {
        self.binding(
            get: { _ in recipient.data },
            send: { .recipientInputChanged($0.redacted) }
        )
    }
    
    func validateRecipient() -> NighthawkTextFieldValidationState {
        self.isRecipientValid ? .valid : .invalid(error: L10n.Nighthawk.TransferTab.Recipient.invalid)
    }
}