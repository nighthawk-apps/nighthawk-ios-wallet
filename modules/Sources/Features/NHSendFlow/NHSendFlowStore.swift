//
//  NHSendFlowStore.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import ComposableArchitecture
import DerivationTool
import Generated
import LocalAuthenticationClient
import NHUserPreferencesStorage
import MnemonicClient
import SDKSynchronizer
import SwiftUI
import Utils
import WalletStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

public typealias NHSendFlowStore = Store<NHSendFlowReducer.State, NHSendFlowReducer.Action>
public typealias NHSendFlowViewStore = ViewStore<NHSendFlowReducer.State, NHSendFlowReducer.Action>

public struct NHSendFlowReducer: ReducerProtocol {
    private enum SyncStatusUpdatesID { case timer }
    let networkType: NetworkType
    
    public struct Path: ReducerProtocol {
        let networkType: NetworkType
        
        public enum State: Equatable {
            case addMemo(AddMemoReducer.State)
            case failed(FailedReducer.State)
            case recipient(RecipientReducer.State)
            case review(ReviewReducer.State)
            case scan(NHScanReducer.State)
            case sending(SendingReducer.State)
            case success(SuccessReducer.State)
        }
        
        public enum Action: Equatable {
            case addMemo(AddMemoReducer.Action)
            case failed(FailedReducer.Action)
            case recipient(RecipientReducer.Action)
            case review(ReviewReducer.Action)
            case scan(NHScanReducer.Action)
            case sending(SendingReducer.Action)
            case success(SuccessReducer.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerProtocol<State, Action> {
            Scope(state: /State.addMemo, action: /Action.addMemo) {
                AddMemoReducer()
            }
            
            Scope(state: /State.failed, action: /Action.failed) {
                FailedReducer()
            }
            
            Scope(state: /State.recipient, action: /Action.recipient) {
                RecipientReducer(networkType: networkType)
            }
            
            Scope(state: /State.review, action: /Action.review) {
                ReviewReducer(networkType: networkType)
            }
            
            Scope(state: /State.scan, action: /Action.scan) {
                NHScanReducer(networkType: networkType)
            }
            
            Scope(state: /State.sending, action: /Action.sending) {
                SendingReducer()
            }
            
            Scope(state: /State.success, action: /Action.success) {
                SuccessReducer()
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
        case authenticationResponse(Bool)
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
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.nhUserStoredPreferences) var nhUserPreferencesStorage
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case let .path(.element(id: id, action: .addMemo(.continueOrSkipTapped))):
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
            case .path(.element(id: _, action: .recipient(.continueTapped))):
                guard derivationTool.isZcashAddress(state.recipient.data, networkType) else { return .none }
                if derivationTool.isTransparentAddress(state.recipient.data, networkType) {
                    state.path.append(
                        Path.State.review(
                            .init(
                                subtotal: state.amountToSend,
                                memo: state.memo,
                                recipient: state.recipient
                            )
                        )
                    )
                } else {
                    var addMemoState = AddMemoReducer.State()
                    addMemoState.memoCharLimit = state.memoCharLimit
                    state.path.append(Path.State.addMemo(addMemoState))
                }
                
                return .none
            case .path(.element(id: _, action: .recipient(.scanQRCodeTapped))):
                state.path.append(Path.State.scan(.init()))
                return .none
            case let .path(.element(id: _, action: .scan(.found(code)))):
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
            case .path(.element(id: _, action: .review(.sendZcashTapped))):
                if nhUserPreferencesStorage.areBiometricsEnabled() {
                    return .task {
                        let context = localAuthenticationContext()
                        
                        do {
                            if try context.canEvaluatePolicy(.deviceOwnerAuthentication) {
                                return try await .authenticationResponse(
                                    context.evaluatePolicy(
                                        .deviceOwnerAuthentication,
                                        L10n.Nighthawk.LocalAuthentication.sendFundsReason
                                    )
                                )
                            } else {
                                return .authenticationResponse(false)
                            }
                        } catch {
                            return .authenticationResponse(false)
                        }
                    }
                } else {
                    return .run { send in await send(.sendTransaction) }
                }
                
            case let .authenticationResponse(authenticated):
                if authenticated {
                    return .run { send in await send(.sendTransaction) }
                }
                return .none
                
            case .continueTapped:
                state.path.append(Path.State.recipient(.init()))
                return .none
            case .onAppear:
                state.memoCharLimit = zcashSDKEnvironment.memoCharLimit
                return sdkSynchronizer.stateStream()
                    .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                    .map(NHSendFlowReducer.Action.synchronizerStateChanged)
                    .eraseToEffect()
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
                    
                    let recipient = try Recipient(state.recipient.data, network: networkType)
                    var memo: Memo?
                    if (/Recipient.transparent).extract(from: recipient) == nil, let memoStr = state.memo?.data, !memoStr.isEmpty {
                        memo = try Memo(string: memoStr)
                    }
                    return .run { [state, memo] send in
                        do {
                            await send(NHSendFlowReducer.Action.sendTransactionInProgress)
                            _ = try await sdkSynchronizer.sendTransaction(
                                spendingKey,
                                state.amountToSend,
                                recipient,
                                memo
                            )
                            await send(NHSendFlowReducer.Action.sendTransactionSuccess)
                        } catch {
                            await send(NHSendFlowReducer.Action.sendTransactionFailure)
                        }
                    }
                } catch {
                    return .task { .sendTransactionFailure }
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
                state.path.append(NHSendFlowReducer.Path.State.sending(.init()))
                return .none
            case .sendTransactionSuccess:
                state.isSendingTransaction = false
                state.path.append(NHSendFlowReducer.Path.State.success(.init()))
                return .none
            case let .synchronizerStateChanged(latestState):
                let shieldedBalance = latestState.shieldedBalance
                state.shieldedBalance = shieldedBalance.redacted
                state.maxAmount = shieldedBalance.verified
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
    }
}

// MARK: - Store
extension NHSendFlowStore {
    func stackStore() -> Store<
        StackState<NHSendFlowReducer.Path.State>,
        StackAction<NHSendFlowReducer.Path.State, NHSendFlowReducer.Path.Action>
    > {
        scope(state: \.path, action: { .path($0) })
    }
}

// MARK: - Placeholder
extension NHSendFlowReducer.State {
    public static var placeholder: Self {
        .init()
    }
}
