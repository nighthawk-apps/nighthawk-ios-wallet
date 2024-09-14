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

@Reducer
public struct SendFlow {
    private enum SyncStatusUpdatesID { case timer }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Path {
        case addMemo(AddMemo)
        case failed(SendFailed)
        case recipient(Recipient)
        case review(Review)
        case scan(Scan)
        case sending
        case success(SendSuccess)
    }
    
    @ObservableState
    public struct State: Equatable {
        public var path: StackState<Path.State>
        public var showCloseButton: Bool
        public var toast: Toast?
        @Presents public var alert: AlertState<Action.Alert>?

        public var unifiedAddress: UnifiedAddress?
        public var spendableBalance = Zatoshi.zero
        public var memoCharLimit = 0
        public var isSendingTransaction = false
        
        // Inputs
        public var amountToSendInput = "0"
        public var amountToSend: Zatoshi {
            Zatoshi.from(decimalString: amountToSendInput) ?? .zero
        }
        public var recipient: String?
        public var memo: RedactableString?
        public var proposal: Proposal?
        public var feeRequired: Zatoshi {
            proposal?.totalFeeRequired() ?? Zatoshi(0)
        }
        
        // Helpers
        public var hasEnteredAmount: Bool { amountToSend > .zero }
        public var hasEnteredRecipient: Bool { recipient?.isEmpty != true }
        public var canSendEnteredAmount: Bool {
            amountToSend.amount < spendableBalance.amount
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
        
        public var tokenName: String {
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            return zcashSDKEnvironment.tokenName
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
        case alert(PresentationAction<Alert>)
        case path(StackAction<Path.State, Path.Action>)
        case binding(BindingAction<State>)
        case closeButtonTapped
        case continueTapped
        case delegate(Delegate)
        case onAppear
        case proposeSendTransactionFailure(ZcashError)
        case review(Review.State)
        case scanCodeTapped
        case sendTransaction
        case sendTransactionFailure
        case sendTransactionInProgress
        case sendTransactionSuccess(TransactionState)
        case setProposal(Proposal)
        case synchronizerStateChanged(SynchronizerState)
        case topUpWalletTapped
        
        public enum Alert: Equatable {
            case proposeTransactionFailed(ZcashError)
        }
        
        public enum Delegate: Equatable {
            case showPartners
        }
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
            case .alert:
                return .none
            case .closeButtonTapped:
                return .run { _ in await self.dismiss() }
            case .continueTapped:
                if state.recipient == nil {
                    state.path.append(Path.State.recipient(.init()))
                    return .none
                }
                
                if state.memo == nil && derivationTool.isSaplingAddress(state.recipient!, zcashSDKEnvironment.network.networkType) {
                    var addMemoState = AddMemo.State(unifiedAddress: state.unifiedAddress)
                    addMemoState.memoCharLimit = state.memoCharLimit
                    state.path.append(Path.State.addMemo(addMemoState))
                    return .none
                }
                
                return .run { [state] send in
                    do {
                        let recipient = try ZcashLightClientKit.Recipient(state.recipient!, network: zcashSDKEnvironment.network.networkType)
                        
                        let memo: Memo?
                        if let memoText = state.memo?.data {
                            memo = memoText.isEmpty ? nil : try Memo(string: memoText)
                        } else {
                            memo = nil
                        }
                        
                        let proposal = try await sdkSynchronizer.proposeTransfer(0, recipient, state.amountToSend, memo)
                        
                        await send(.setProposal(proposal))
                        await send(
                            .review(
                                .init(
                                    zecAmount: state.amountToSend,
                                    memo: state.memo,
                                    recipient: state.recipient!,
                                    latestFiatPrice: state.latestFiatPrice,
                                    proposal: proposal
                                )
                            )
                        )
                    } catch {
                        await send(SendFlow.Action.proposeSendTransactionFailure(error.toZcashError()))
                    }
                }
            case .delegate:
                return .none
            case .onAppear:
                state.memoCharLimit = zcashSDKEnvironment.memoCharLimit
                return .publisher {
                    sdkSynchronizer.stateStream()
                        .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                        .map(SendFlow.Action.synchronizerStateChanged)
                }
                .cancellable(id: SyncStatusUpdatesID.timer, cancelInFlight: true)
            case let .proposeSendTransactionFailure(error):
                if case let .rustCreateToAddress(message) = error {
                    state.alert = AlertState.proposeTransferFailed(message)
                } else {
                    state.alert = AlertState.proposeTransferFailed(error.message)
                }
                return .none
            case let .review(reviewState):
                state.path.append(Path.State.review(reviewState))
                return .none
            case .scanCodeTapped:
                state.path.append(.scan(.init()))
                return .none
            case .sendTransaction:
                guard !state.isSendingTransaction,
                    let recipientStr = state.recipient else { return .none }
                
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                    let spendingKey = try derivationTool.deriveSpendingKey(seedBytes, 0, zcashSDKEnvironment.network.networkType)
                    
                    state.isSendingTransaction = true
                    
                    let recipient = try ZcashLightClientKit.Recipient(recipientStr, network: zcashSDKEnvironment.network.networkType)
                    var memo: Memo?
                    if recipient[case: \.transparent] == nil, let memoStr = state.memo?.data, !memoStr.isEmpty {
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
            case let .setProposal(proposal):
                state.proposal = proposal
                return .none
            case let .synchronizerStateChanged(latestState):
                state.spendableBalance = (latestState.accountBalance?.saplingBalance.spendableValue ?? .zero) + (latestState.accountBalance?.orchardBalance.spendableValue ?? .zero)
                return .none
            case .topUpWalletTapped:
                return .send(.delegate(.showPartners))
            case .binding, .path:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .forEach(\.path, action: \.path)
        
        addMemoDelegateReducer()
        recipientDelegateReducer()
        scanDelegateReducer()
        reviewDelegateReducer()
    }
    
    public init() {}
}

// MARK: Alerts
extension AlertState where Action == SendFlow.Action.Alert {
    public static func proposeTransferFailed(_ message: String) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWallet)
        } actions: {
            ButtonState {
                TextState(L10n.General.ok)
            }
        } message: {
            TextState(L10n.Nighthawk.TransferTab.Send.proposalFailed(message))
        }
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
                        state.proposal = nil
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
                    
                    if let recipientString = state.recipient {
                        return .run { [state] send in
                            do {
                                let recipient = try ZcashLightClientKit.Recipient(recipientString, network: zcashSDKEnvironment.network.networkType)
                                
                                let memo: Memo?
                                if let memoText = state.memo?.data {
                                    memo = memoText.isEmpty ? nil : try Memo(string: memoText)
                                } else {
                                    memo = nil
                                }
                                
                                let proposal = try await sdkSynchronizer.proposeTransfer(0, recipient, state.amountToSend, memo)
                                
                                await send(.setProposal(proposal))
                                await send(
                                    .review(
                                        .init(
                                            zecAmount: state.amountToSend,
                                            memo: state.memo,
                                            recipient: state.recipient!,
                                            latestFiatPrice: state.latestFiatPrice,
                                            proposal: proposal
                                        )
                                    )
                                )
                            } catch {
                                await send(SendFlow.Action.proposeSendTransactionFailure(error.toZcashError()))
                            }
                        }
                    } else {
                        state.path.append(.recipient(.init()))
                    }
                    
                    return .none
                }
            case .alert,
                 .binding,
                 .closeButtonTapped,
                 .continueTapped,
                 .delegate,
                 .onAppear,
                 .path,
                 .proposeSendTransactionFailure,
                 .review,
                 .scanCodeTapped,
                 .sendTransaction,
                 .sendTransactionFailure,
                 .sendTransactionInProgress,
                 .sendTransactionSuccess,
                 .setProposal,
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
                        state.proposal = nil
                    }
                    
                    let _ = state.path.popLast()
                    return .none
                case let .proceedWithRecipient(recipient):
                    guard derivationTool.isZcashAddress(recipient, zcashSDKEnvironment.network.networkType) else { return .none }
                    state.recipient = recipient
                    if derivationTool.isTransparentAddress(recipient, zcashSDKEnvironment.network.networkType) {
                        return .run { [state] send in
                            do {
                                let recipient = try ZcashLightClientKit.Recipient(state.recipient!, network: zcashSDKEnvironment.network.networkType)
                                
                                let memo: Memo?
                                if let memoText = state.memo?.data {
                                    memo = memoText.isEmpty ? nil : try Memo(string: memoText)
                                } else {
                                    memo = nil
                                }
                                
                                let proposal = try await sdkSynchronizer.proposeTransfer(0, recipient, state.amountToSend, memo)
                                
                                await send(.setProposal(proposal))
                                await send(
                                    .review(
                                        .init(
                                            zecAmount: state.amountToSend,
                                            memo: state.memo,
                                            recipient: state.recipient!,
                                            latestFiatPrice: state.latestFiatPrice,
                                            proposal: proposal
                                        )
                                    )
                                )
                            } catch {
                                await send(SendFlow.Action.proposeSendTransactionFailure(error.toZcashError()))
                            }
                        }
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
            case .alert,
                 .binding,
                 .closeButtonTapped,
                 .continueTapped,
                 .delegate,
                 .onAppear,
                 .path,
                 .proposeSendTransactionFailure,
                 .review,
                 .scanCodeTapped,
                 .sendTransaction,
                 .sendTransactionFailure,
                 .sendTransactionInProgress,
                 .sendTransactionSuccess,
                 .setProposal,
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
                    state.recipient = result.address
                    state.amountToSendInput = result.amount ?? state.amountToSendInput
                    state.memo = result.memo?.redacted
                    let _ = state.path.popLast()
                    
                    if let address = state.recipient, !address.isEmpty {
                        if !state.hasEnteredAmount {
                            state.path = StackState()
                            return .none
                        }
                        
                        if state.amountToSend.amount > state.spendableBalance.amount {
                            state.amountToSendInput = "0"
                            state.recipient = nil
                            state.memo = nil
                            state.proposal = nil
                            state.path = StackState()
                            state.toast = .notEnoughZcash
                            return .none
                        }
                        
                        if state.memo == nil && !derivationTool.isTransparentAddress(address, zcashSDKEnvironment.network.networkType) {
                            var addMemoState = AddMemo.State(unifiedAddress: state.unifiedAddress)
                            addMemoState.memoCharLimit = state.memoCharLimit
                            state.path.append(Path.State.addMemo(addMemoState))
                            return .none
                        }
                        
                        return .run { [state] send in
                            do {
                                let recipient = try ZcashLightClientKit.Recipient(state.recipient!, network: zcashSDKEnvironment.network.networkType)
                                
                                let memo: Memo?
                                if let memoText = state.memo?.data {
                                    memo = memoText.isEmpty ? nil : try Memo(string: memoText)
                                } else {
                                    memo = nil
                                }
                                
                                let proposal = try await sdkSynchronizer.proposeTransfer(0, recipient, state.amountToSend, memo)
                                
                                await send(.setProposal(proposal))
                                await send(
                                    .review(
                                        .init(
                                            zecAmount: state.amountToSend,
                                            memo: state.memo,
                                            recipient: state.recipient!,
                                            latestFiatPrice: state.latestFiatPrice,
                                            proposal: proposal
                                        )
                                    )
                                )
                            } catch {
                                await send(SendFlow.Action.proposeSendTransactionFailure(error.toZcashError()))
                            }
                        }
                    }
                    
                    return .none
                }
                
            case .alert,
                 .binding,
                 .closeButtonTapped,
                 .continueTapped,
                 .delegate,
                 .onAppear,
                 .path,
                 .proposeSendTransactionFailure,
                 .review,
                 .scanCodeTapped,
                 .sendTransaction,
                 .sendTransactionFailure,
                 .sendTransactionInProgress,
                 .sendTransactionSuccess,
                 .setProposal,
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
                        state.proposal = nil
                    }
                    
                    let _ = state.path.popLast()
                    return .none
                case .sendZcash:
                    return .send(.sendTransaction)
                }
            case .alert,
                 .binding,
                 .closeButtonTapped,
                 .continueTapped,
                 .delegate,
                 .onAppear,
                 .path,
                 .proposeSendTransactionFailure,
                 .review,
                 .scanCodeTapped,
                 .sendTransaction,
                 .sendTransactionFailure,
                 .sendTransactionInProgress,
                 .sendTransactionSuccess,
                 .setProposal,
                 .synchronizerStateChanged,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
}
