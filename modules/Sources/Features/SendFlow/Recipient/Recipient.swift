//
//  Recipient.swift
//  
//
//  Created by Matthew watt on 7/23/23.
//

import ComposableArchitecture
import Pasteboard
import SwiftUI
import Utils
import ZcashLightClientKit

public struct Recipient: ReducerProtocol {
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
        case onAppear
        case pasteFromClipboardTapped
        case recipientInputChanged(RedactableString)
        case scanQRCodeTapped
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.pasteboard) var pasteboard
    
    public var body: some ReducerProtocolOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in await self.dismiss() }
            case .clearRecipientTapped:
                state.recipient = "".redacted
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
            case .scanQRCodeTapped, .continueTapped:
                return .none
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
}
