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
import SDKSynchronizer
import SwiftUI
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
        public var path = StackState<Path.State>()

        public var shieldedBalance = Balance.zero
        public var memoCharLimit = 0
        public var maxAmount = Zatoshi.zero
        public var isSendingTransaction = false
        
        // Inputs
        @BindingState public var amountToSendInput = "0"
        public var amountToSend: Zatoshi {
            Zatoshi.from(decimalString: amountToSendInput) ?? .zero
        }
        public var recipient: RedactableString = "".redacted
        public var memo: RedactableString?
        
        // Helpers
        public var hasEnteredAmount: Bool { amountToSend > .zero }
        public var hasEnteredRecipient: Bool { !recipient.data.isEmpty }
        public var canSendEnteredAmount: Bool {
             amountToSend <= maxAmount
        }

        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case binding(BindingAction<State>)
        case continueTapped
        case onAppear
        case scanCodeTapped
        case sendTransaction
        case sendTransactionFailure
        case sendTransactionInProgress
        case sendTransactionSuccess
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
            case .continueTapped:
                state.path.append(Path.State.recipient(.init()))
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
                return .none
            case .sendTransaction:
                guard !state.isSendingTransaction else { return .none }
                
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                    let spendingKey = try derivationTool.deriveSpendingKey(seedBytes, 0, networkType)
                    
                    state.isSendingTransaction = true
                    
                    let recipient = try ZcashLightClientKit.Recipient(state.recipient.data, network: networkType)
                    var memo: Memo?
                    if (/ZcashLightClientKit.Recipient.transparent).extract(from: recipient) == nil, let memoStr = state.memo?.data, !memoStr.isEmpty {
                        memo = try Memo(string: memoStr)
                    }
                    return .run { [state, memo] send in
                        do {
                            await send(SendFlow.Action.sendTransactionInProgress)
                            _ = try await sdkSynchronizer.sendTransaction(
                                spendingKey,
                                state.amountToSend,
                                recipient,
                                memo
                            )
                            await send(SendFlow.Action.sendTransactionSuccess)
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
            case .sendTransactionSuccess:
                state.isSendingTransaction = false
                state.path.append(SendFlow.Path.State.success(.init()))
                return .none
            case let .synchronizerStateChanged(latestState):
                let shieldedBalance = latestState.shieldedBalance
                state.shieldedBalance = shieldedBalance.redacted
                // TODO: [#1186] Use ZIP-317 fees when SDK supports it
                state.maxAmount = shieldedBalance.verified - Zatoshi(10_000)
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
        successDelegateReducer()
        failedDelegateReducer()
    }
}

// MARK: Add memo delegate
extension SendFlow {
    func addMemoDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: id, action: .addMemo(.delegate(delegateAction)))):
                switch delegateAction {
                case .nextScreen:
                    guard case let .addMemo(addMemoState) = state.path[id: id]
                    else { return .none }
                    state.memo = addMemoState.memo
                    state.path.append(
                        Path.State.review(
                            .init(
                                subtotal: state.amountToSend,
                                memo: state.memo,
                                recipient: state.recipient
                            )
                        )
                    )
                    return .none
                }
            case .binding,
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
                case let .proceedWithRecipient(recipient):
                    state.recipient = recipient
                    guard derivationTool.isZcashAddress(recipient.data, networkType) else { return .none }
                    if derivationTool.isTransparentAddress(recipient.data, networkType) {
                        state.path.append(
                            Path.State.review(
                                .init(
                                    subtotal: state.amountToSend,
                                    memo: state.memo,
                                    recipient: recipient
                                )
                            )
                        )
                    } else {
                        var addMemoState = AddMemo.State()
                        addMemoState.memoCharLimit = state.memoCharLimit
                        state.path.append(Path.State.addMemo(addMemoState))
                    }
                    return .none
                case .scanCode:
                    state.path.append(Path.State.scan(.init()))
                    return .none
                }
            case .binding,
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
            case let .path(.element(id: _, action: .scan(.delegate(.handleCode(code))))):
                state.recipient = code
                state.path = StackState(
                    state.path.map { state in
                        if case var .recipient(recipientState) = state {
                            recipientState.recipient = code
                            return Path.State.recipient(recipientState)
                        }
                    
                        return state
                    }
                )
                let _ = state.path.popLast()
                return .none
            case .binding,
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
            case .path(.element(id: _, action: .review(.delegate(.sendZcash)))):
                return .send(.sendTransaction)
            case .binding,
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

// MARK: Success delegate
extension SendFlow {
    func successDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            switch action {
            case .path(.element(id: _, action: .success(.delegate(.goHome)))):
                // TODO: This doesn't seem to be working.
                return .run { _ in await self.dismiss() }
            case .binding,
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

// MARK: Failed delegate
extension SendFlow {
    func failedDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .failed(.delegate(delegateAction)))):
                switch delegateAction {
                case .cancelTransaction:
                    // TODO: this doesn't seem to be working
                    return .run { _ in await self.dismiss() }
                }
            case .binding,
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
