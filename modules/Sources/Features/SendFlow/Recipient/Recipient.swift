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
import ZcashSDKEnvironment

@Reducer
public struct Recipient {
    @ObservableState
    public struct State: Equatable {
        public var recipient = ""
        public var hasEnteredRecipient: Bool { recipient.isEmpty == false }
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
        case recipientInputChanged(String)
        case resolveUNSFinished
        case resolveUNSRequest
        case resolveUNSSuccess(String)
        case scanQRCodeTapped
        
        public enum Delegate: Equatable {
            case goBack
            case proceedWithRecipient(String)
            case scanCode
        }
    }
    
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.unsClient) var unsClient
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
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
                    state.pasteboardContainsZAddress = derivationTool.isZcashAddress(contents.data, zcashSDKEnvironment.network.networkType)
                }
                return .none
            case .pasteFromClipboardTapped:
                guard let contents = pasteboard.getString(),
                      derivationTool.isZcashAddress(contents.data, zcashSDKEnvironment.network.networkType) else { return .none }
                return .send(.recipientInputChanged(contents.data))
            case let .recipientInputChanged(recipient):
                state.recipient = recipient
                let validZcash = derivationTool.isZcashAddress(recipient, zcashSDKEnvironment.network.networkType)
                state.isRecipientValid = validZcash
                if !validZcash && !recipient.isEmpty && userStoredPreferences.isUnstoppableDomainsEnabled() {
                    return .run { send in
                        enum CancelID { case resolveUNSDebounce }
                        try await withTaskCancellation(id: CancelID.resolveUNSDebounce, cancelInFlight: true) {
                            try await clock.sleep(for: .seconds(1))
                            await send(.resolveUNSRequest)
                            if let resolved = try? await unsClient.resolveUNSAddress(recipient) {
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
                state.recipient = resolved
                state.isRecipientValid = derivationTool.isZcashAddress(resolved, zcashSDKEnvironment.network.networkType)
                state.isResolvingUNS = false
                return .none
            case .scanQRCodeTapped:
                return .send(.delegate(.scanCode))
            }
        }
    }
    
    public init() {}
}
