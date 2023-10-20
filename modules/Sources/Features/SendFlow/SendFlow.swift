//
//  SendFlow.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import ComposableArchitecture
import DerivationTool
import Generated
import LocalAuthenticationClient
import UserPreferencesStorage
import MnemonicClient
import Models
import ProcessInfoClient
import SDKSynchronizer
import SwiftUI
import UserPreferencesStorage
import Utils
import WalletStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct SendFlow: Reducer {
    private enum SyncStatusUpdatesID { case timer }
    let networkType: NetworkType
    
    public struct Path: Reducer {
        let networkType: NetworkType
        
        public enum State: Equatable {
            case addMemo(AddMemo.State)
            case failed(SendFailed.State)
            case recipient(Recipient.State)
            case review(Review.State)
            case scan(Scan.State)
            case sending
            case success(SendSuccess.State)
        }
        
        public enum Action: Equatable {
            case addMemo(AddMemo.Action)
            case failed(SendFailed.Action)
            case recipient(Recipient.Action)
            case review(Review.Action)
            case scan(Scan.Action)
            case sending(Never)
            case success(SendSuccess.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.addMemo, action: /Action.addMemo) {
                AddMemo()
            }
            
            Scope(state: /State.failed, action: /Action.failed) {
                SendFailed()
            }
            
            Scope(state: /State.recipient, action: /Action.recipient) {
                Recipient(networkType: networkType)
            }
            
            Scope(state: /State.review, action: /Action.review) {
                Review(networkType: networkType)
            }
            
            Scope(state: /State.scan, action: /Action.scan) {
                Scan(networkType: networkType)
            }
            
            Scope(state: /State.success, action: /Action.success) {
                SendSuccess()
            }
        }
    }
    
    
    public struct State: Equatable {
        public var path: StackState<Path.State>
        public var showCloseButton: Bool
        @BindingState public var toast: Toast?

        public var unifiedAddress: UnifiedAddress?
        public var shieldedBalance = Balance.zero
        public var memoCharLimit = 0
        public var maxAmount = Zatoshi.zero
        public var isSendingTransaction = false
        
        // Inputs
        @BindingState public var amountToSendInput = "0"
        public var amountToSend: Zatoshi {
            Zatoshi.from(decimalString: amountToSendInput) ?? .zero
        }
        public var recipient: RedactableString?
        public var memo: RedactableString?
        
        // Helpers
        public var hasEnteredAmount: Bool { amountToSend > .zero }
        public var hasEnteredRecipient: Bool { recipient?.data.isEmpty != true }
        public var canSendEnteredAmount: Bool {
             amountToSend <= maxAmount
        }
        public var preferredCurrency: NighthawkSetting.FiatCurrency {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return userStoredPreferences.fiatCurrency()
        }
        public var latestFiatPrice: Double?
        public var fiatConversion: (NighthawkSetting.FiatCurrency, Double)? {
            if let latestFiatPrice, preferredCurrency != .off {
                (preferredCurrency, latestFiatPrice)
            } else {
                nil
            }
        }
        
        public var showScanButton: Bool {
            @Dependency(\.processInfo) var processInfo
            return !processInfo.isiOSAppOnMac()
        }
        
        public enum Toast {
            case notEnoughZcash
        }

        public init(
            path: StackState<Path.State> = .init(),
            latestFiatPrice: Double?,
            showCloseButton: Bool = false
        ) {
            self.path = path
            self.latestFiatPrice = latestFiatPrice
            self.showCloseButton = showCloseButton
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case binding(BindingAction<State>)
        case closeButtonTapped
        case continueTapped
        case onAppear
        case scanCodeTapped
        case sendTransaction
        case sendTransactionFailure
        case sendTransactionInProgress
        case sendTransactionSuccess(TransactionState)
        case synchronizerStateChanged(SynchronizerState)
        case topUpWalletTapped
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.userStoredPreferences) var userPreferencesStorage
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                return .run { _ in await self.dismiss() }
            case .continueTapped:
                if state.recipient == nil {
                    state.path.append(Path.State.recipient(.init()))
                    return .none
                }
                
                if state.memo == nil && derivationTool.isSaplingAddress(state.recipient!.data, networkType) {
                    var addMemoState = AddMemo.State(unifiedAddress: state.unifiedAddress)
                    addMemoState.memoCharLimit = state.memoCharLimit
                    state.path.append(Path.State.addMemo(addMemoState))
                    return .none
                }
                
                state.path.append(
                    Path.State.review(
                        .init(
                            zecAmount: state.amountToSend,
                            memo: state.memo,
                            recipient: state.recipient!,
                            latestFiatPrice: state.latestFiatPrice
                        )
                    )
                )
                
                return .none
            case .onAppear:
                state.memoCharLimit = zcashSDKEnvironment.memoCharLimit
                return .publisher {
                    sdkSynchronizer.stateStream()
                        .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                        .map(SendFlow.Action.synchronizerStateChanged)
                }
                .cancellable(id: SyncStatusUpdatesID.timer, cancelInFlight: true)
            case .scanCodeTapped:
                state.path.append(.scan(.init()))
                return .none
            case .sendTransaction:
                guard !state.isSendingTransaction, 
                    let recipientStr = state.recipient?.data else { return .none }
                
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                    let spendingKey = try derivationTool.deriveSpendingKey(seedBytes, 0, networkType)
                    
                    state.isSendingTransaction = true
                    
                    let recipient = try ZcashLightClientKit.Recipient(recipientStr, network: networkType)
                    var memo: Memo?
                    if (/ZcashLightClientKit.Recipient.transparent).extract(from: recipient) == nil, let memoStr = state.memo?.data, !memoStr.isEmpty {
                        memo = try Memo(string: memoStr)
                    }
                    return .run { [state, memo] send in
                        do {
                            await send(SendFlow.Action.sendTransactionInProgress)
                            let txn = try await sdkSynchronizer.sendTransaction(
                                spendingKey,
                                state.amountToSend,
                                recipient,
                                memo
                            )
                            await send(SendFlow.Action.sendTransactionSuccess(txn))
                        } catch {
                            await send(SendFlow.Action.sendTransactionFailure)
                        }
                    }
                } catch {
                    return .send(.sendTransactionFailure)
                }
            case .sendTransactionFailure:
                state.isSendingTransaction = false
                state.path = state.path.filter { state in
                    if case .sending = state {
                        return false
                    }
                    
                    return true
                }
                state.path.append(Path.State.failed(.init()))
                return .none
            case .sendTransactionInProgress:
                state.path.append(SendFlow.Path.State.sending)
                return .none
            case let .sendTransactionSuccess(transaction):
                state.isSendingTransaction = false
                state.path.append(SendFlow.Path.State.success(.init(transaction: transaction)))
                return .none
            case let .synchronizerStateChanged(latestState):
                let shieldedBalance = latestState.shieldedBalance
                state.shieldedBalance = shieldedBalance.redacted
                // TODO: [#1186] Use ZIP-317 fees when SDK supports it
                state.maxAmount = max(shieldedBalance.verified - Zatoshi(10_000), .zero)
                return .none
            case .topUpWalletTapped:
                return .none
            case .binding, .path:
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path(networkType: networkType)
        }
        
        addMemoDelegateReducer()
        recipientDelegateReducer()
        scanDelegateReducer()
        reviewDelegateReducer()
    }
}

// MARK: Add memo delegate
extension SendFlow {
    func addMemoDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: id, action: .addMemo(.delegate(delegateAction)))):
                switch delegateAction {
                case .goBack:
                    if state.path.count == 1 {
                        // Returning from recipient will take us back to amount entry
                        // Reset the transaction
                        state.amountToSendInput = "0"
                        state.recipient = nil
                        state.memo = nil
                    }
                    
                    let _ = state.path.popLast()
                    return .none
                case .nextScreen:
                    guard case let .addMemo(addMemoState) = state.path[id: id]
                    else { return .none }
                    state.memo = if addMemoState.isIncludeReplyToChecked, let ua = state.unifiedAddress?.stringEncoded {
                        "\(addMemoState.memo)\nReply to: \(ua)".redacted
                    } else {
                        addMemoState.memo.redacted
                    }
                    
                    if let recipient = state.recipient {
                        state.path.append(
                            Path.State.review(
                                .init(
                                    zecAmount: state.amountToSend,
                                    memo: state.memo,
                                    recipient: recipient,
                                    latestFiatPrice: state.latestFiatPrice
                                )
                            )
                        )
                    } else {
                        state.path.append(.recipient(.init()))
                    }
                    
                    return .none
                }
            case .binding,
                 .closeButtonTapped,
                 .continueTapped,
                 .onAppear,
                 .path,
                 .scanCodeTapped,
                 .sendTransaction,
                 .sendTransactionFailure,
                 .sendTransactionInProgress,
                 .sendTransactionSuccess,
                 .synchronizerStateChanged,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
}

// MARK: Recipient delegate
extension SendFlow {
    func recipientDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .recipient(.delegate(delegateAction)))):
                switch delegateAction {
                case .goBack:
                    if state.path.count == 1 {
                        // Returning from recipient will take us back to amount entry
                        // Reset the transaction
                        state.amountToSendInput = "0"
                        state.recipient = nil
                        state.memo = nil
                    }
                    
                    let _ = state.path.popLast()
                    return .none
                case let .proceedWithRecipient(recipient):
                    guard derivationTool.isZcashAddress(recipient.data, networkType) else { return .none }
                    state.recipient = recipient
                    if derivationTool.isTransparentAddress(recipient.data, networkType) {
                        state.path.append(
                            Path.State.review(
                                .init(
                                    zecAmount: state.amountToSend,
                                    memo: state.memo,
                                    recipient: recipient,
                                    latestFiatPrice: state.latestFiatPrice
                                )
                            )
                        )
                    } else {
                        var addMemoState = AddMemo.State(unifiedAddress: state.unifiedAddress)
                        addMemoState.memoCharLimit = state.memoCharLimit
                        state.path.append(Path.State.addMemo(addMemoState))
                    }
                    return .none
                case .scanCode:
                    state.path.append(Path.State.scan(.init()))
                    return .none
                }
            case .binding,
                 .closeButtonTapped,
                 .continueTapped,
                 .onAppear,
                 .path,
                 .scanCodeTapped,
                 .sendTransaction,
                 .sendTransactionFailure,
                 .sendTransactionInProgress,
                 .sendTransactionSuccess,
                 .synchronizerStateChanged,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
}

// MARK: Scan delegate
extension SendFlow {
    func scanDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .scan(.delegate(delegateAction)))):
                switch delegateAction {
                case .goHome:
                    return .none
                case let .handleParseResult(result):
                    state.recipient = result.address.redacted
                    state.amountToSendInput = result.amount ?? state.amountToSendInput
                    state.memo = result.memo?.redacted
                    let _ = state.path.popLast()
                    
                    if let address = state.recipient, !address.data.isEmpty {
                        if !state.hasEnteredAmount {
                            state.path = StackState()
                            return .none
                        }
                        
                        if state.amountToSend > (state.maxAmount - Zatoshi(10_000)) {
                            state.amountToSendInput = "0"
                            state.recipient = nil
                            state.memo = nil
                            state.path = StackState()
                            state.toast = .notEnoughZcash
                            return .none
                        }
                        
                        if state.memo == nil && derivationTool.isSaplingAddress(address.data, networkType) {
                            var addMemoState = AddMemo.State(unifiedAddress: state.unifiedAddress)
                            addMemoState.memoCharLimit = state.memoCharLimit
                            state.path.append(Path.State.addMemo(addMemoState))
                            return .none
                        }
                        
                        state.path.append(
                            .review(
                                .init(
                                    zecAmount: state.amountToSend,
                                    memo: state.memo,
                                    recipient: address,
                                    latestFiatPrice: state.latestFiatPrice
                                )
                            )
                        )
                    }
                    
                    return .none
                }
                
            case .binding,
                 .closeButtonTapped,
                 .continueTapped,
                 .onAppear,
                 .path,
                 .scanCodeTapped,
                 .sendTransaction,
                 .sendTransactionFailure,
                 .sendTransactionInProgress,
                 .sendTransactionSuccess,
                 .synchronizerStateChanged,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
}

// MARK: Review delegate
extension SendFlow {
    func reviewDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .review(.delegate(delegateAction)))):
                switch delegateAction {
                case .goBack:
                    if state.path.count == 1 {
                        // Returning from review will take us back to amount entry
                        // Reset the transaction
                        state.amountToSendInput = "0"
                        state.recipient = nil
                        state.memo = nil
                    }
                    
                    let _ = state.path.popLast()
                    return .none
                case .sendZcash:
                    return .send(.sendTransaction)
                }
            case .binding,
                 .closeButtonTapped,
                 .continueTapped,
                 .onAppear,
                 .path,
                 .scanCodeTapped,
                 .sendTransaction,
                 .sendTransactionFailure,
                 .sendTransactionInProgress,
                 .sendTransactionSuccess,
                 .synchronizerStateChanged,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
}
