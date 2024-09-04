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
import UNSClient
import UserPreferencesStorage
import Utils
import ZcashLightClientKit

public struct Recipient: Reducer {
    let networkType: NetworkType
    
    public struct State: Equatable {
        public var recipient = "".redacted
        public var hasEnteredRecipient: Bool { recipient.data.isEmpty == false }
        public var pasteboardContainsZAddress = false
        public var canPasteAddress: Bool { pasteboardContainsZAddress && !hasEnteredRecipient }
        public var specificValidationError: NighthawkTextFieldValidationState?
        public var isRecipientValid = false
        public var isResolvingUNS = false
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
        case recipientInputChanged(RedactableString)
        case resolveUNSFinished
        case resolveUNSRequest
        case resolveUNSSuccess(String)
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
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.unsClient) var unsClient
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .send(.delegate(.goBack))
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
                return .send(.recipientInputChanged(contents))
            case let .recipientInputChanged(redactedRecipient):
                state.recipient = redactedRecipient
                let validZcash = derivationTool.isZcashAddress(redactedRecipient.data, networkType)
                state.isRecipientValid = validZcash
                if !validZcash && !redactedRecipient.data.isEmpty && userStoredPreferences.isUnstoppableDomainsEnabled() {
                    return .run { send in
                        enum CancelID { case resolveUNSDebounce }
                        try await withTaskCancellation(id: CancelID.resolveUNSDebounce, cancelInFlight: true) {
                            try await clock.sleep(for: .seconds(1))
                            await send(.resolveUNSRequest)
                            if let resolved = try? await unsClient.resolveUNSAddress(redactedRecipient.data) {
                                await send(.resolveUNSSuccess(resolved))
                                return
                            }
                            
                            await send(.resolveUNSFinished)
                        }
                    }
                }
                
                return .none
            case .resolveUNSFinished:
                state.isResolvingUNS = false
                return .none
            case .resolveUNSRequest:
                state.isResolvingUNS = true
                return .none
            case let .resolveUNSSuccess(resolved):
                state.recipient = resolved.redacted
                state.isRecipientValid = derivationTool.isZcashAddress(resolved, networkType)
                state.isResolvingUNS = false
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
        return if self.isRecipientValid {
            .valid
        } else if let specific = self.specificValidationError  {
            specific
        } else {
            .invalid(error: L10n.Nighthawk.TransferTab.Recipient.invalid)
        }
    }
}
