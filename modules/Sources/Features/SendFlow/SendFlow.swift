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
import Utils
import WalletStorage

@Reducer
public struct SendFlow {
    private enum SyncStatusUpdatesID { case timer }

    @Reducer
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

        public var receiveAddress: DarkfiAddress?
        public var spendableBalance = DrkAmount.zero
        public var memoCharLimit = 0
        public var isSendingTransaction = false

        // Inputs
        public var amountToSendInput = "0"
        public var amountToSend: DrkAmount {
            DrkAmount.from(decimalString: amountToSendInput) ?? .zero
        }
        public var recipient: String?
        public var memo: RedactableString?
        public var proposal: Proposal?
        public var feeRequired: DrkAmount {
            proposal?.totalFeeRequired() ?? DrkAmount(0)
        }

        // Helpers
        public static let nativeDrkTokenId = "241vANigf1Cy3ytjM1KHXiVECxgxdK4yApddL8KcLssb"

        public static func isNativeDrkToken(tokenId: String?, displayLabel: String? = nil) -> Bool {
            guard let raw = tokenId?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
                return true
            }
            if raw.caseInsensitiveCompare("DRK") == .orderedSame || raw == nativeDrkTokenId {
                return true
            }
            if let label = displayLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
               label.caseInsensitiveCompare("DRK") == .orderedSame {
                return true
            }
            return false
        }

        public var isNativeDrkSelected: Bool {
            guard let tokenId = selectedTokenId else { return true }
            let matched = availableTokens.first(where: { $0.tokenId == tokenId })
            return Self.isNativeDrkToken(tokenId: tokenId, displayLabel: matched?.displayLabel)
        }

        public var hasEnteredAmount: Bool { amountToSend > .zero }
        public var hasEnteredRecipient: Bool { recipient?.isEmpty != true }
        public var selectedSpendableBalance: DrkAmount {
            if isNativeDrkSelected {
                return spendableBalance
            }
            guard let tokenId = selectedTokenId else {
                return spendableBalance
            }
            return availableTokens.first(where: { $0.tokenId == tokenId })?.balanceAtomic ?? 0
        }
        public var canSendEnteredAmount: Bool {
            guard amountToSend > .zero && amountToSend <= selectedSpendableBalance else {
                return false
            }
            if isNativeDrkSelected {
                if feeRequired > .zero {
                    return amountToSend + feeRequired <= spendableBalance
                }
                return true
            }
            if feeRequired > .zero {
                return spendableBalance >= feeRequired
            }
            return spendableBalance > .zero
        }

        /// Review is reachable only after a proposal exists. A custom token
        /// still pays its fee in DRK, so the review step must see that balance.
        public func customTokenFeeIsCovered(_ proposal: Proposal) -> Bool {
            guard !isNativeDrkSelected else { return true }
            return spendableBalance >= proposal.totalFeeRequired()
        }
        public var preferredCurrency: NighthawkSetting.FiatCurrency = .off
        public var latestFiatPrice: Double?
        public var fiatConversion: (NighthawkSetting.FiatCurrency, Double)? {
            guard isNativeDrkSelected else { return nil }
            if let latestFiatPrice, preferredCurrency != .off {
                return (preferredCurrency, latestFiatPrice)
            } else {
                return nil
            }
        }

        public var showScanButton = true

        /// Selected token for sending (nil = native DRK)
        public var selectedTokenId: String?
        /// Available tokens from wallet (populated from listTokenBalances)
        public var availableTokens: [TokenBalanceInfo] = []

        public var tokenName: String {
            if isNativeDrkSelected {
                return "DRK"
            }
            if let tokenId = selectedTokenId {
                if let token = availableTokens.first(where: { $0.tokenId == tokenId }),
                   let label = token.displayLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !label.isEmpty {
                    return label
                }
                return "\(tokenId.prefix(8))…"
            }
            return "DRK"
        }

        @CasePathable
        public enum Toast {
            case notEnoughDrk
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
        case onAppear
        case proposeSendTransactionFailure(DarkFiError)
        case review(Review.State)
        case scanCodeTapped
        case sendTransaction
        case sendTransactionFailure(String)
        case sendTransactionInProgress
        case sendTransactionSuccess(TransactionState)
        case setProposal(Proposal)
        case synchronizerStateChanged(SynchronizerState)
        case loadTokenBalances
        case tokenBalancesLoaded([TokenBalanceInfo])
        case tokenSelected(String?)

        public enum Alert: Equatable {
            case proposeTransactionFailed(DarkFiError)
        }
    }

    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.userStoredPreferences) var userPreferencesStorage
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.processInfo) var processInfo
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .alert, .binding, .path:
                return .none
            case .closeButtonTapped:
                return .run { _ in await self.dismiss() }
            case .continueTapped:
                return handleContinueTapped(state: &state)
            case .onAppear:
                return handleOnAppear(state: &state)
            case let .proposeSendTransactionFailure(error):
                state.alert = AlertState.proposeTransferFailed(error.message)
                return .none
            case let .review(reviewState):
                state.path.append(Path.State.review(reviewState))
                return .none
            case .scanCodeTapped:
                state.path.append(.scan(.init()))
                return .none
            case .sendTransaction:
                return handleSendTransaction(state: &state)
            case let .sendTransactionFailure(message):
                state.isSendingTransaction = false
                state.path = state.path.filter { if case .sending = $0 { return false }; return true }
                state.path.append(Path.State.failed(.init(errorMessage: message)))
                return .none
            case .sendTransactionInProgress:
                state.path.append(SendFlow.Path.State.sending)
                return .none
            case let .sendTransactionSuccess(transaction):
                state.isSendingTransaction = false
                state.path.append(SendFlow.Path.State.success(.init(transaction: transaction)))
                ChatReceiptBook.markBroadcasted(txId: transaction.id)
                return .none
            case let .setProposal(proposal):
                state.proposal = proposal
                return .none
            case let .synchronizerStateChanged(latestState):
                state.spendableBalance = latestState.confirmedBalance
                return .send(.loadTokenBalances)
            case .loadTokenBalances:
                return .run { send in
                    let balances = (try? await sdkSynchronizer.listTokenBalances()) ?? []
                    await send(.tokenBalancesLoaded(balances))
                }
            case let .tokenBalancesLoaded(balances):
                state.availableTokens = balances
                return .none
            case let .tokenSelected(tokenId):
                state.selectedTokenId = tokenId
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

extension SendFlow.Path.State: Equatable {}
extension SendFlow.Path.Action: Equatable {}

// MARK: - Core action handlers
private extension SendFlow {
    func handleContinueTapped(state: inout State) -> Effect<Action> {
        if state.recipient == nil {
            state.path.append(Path.State.recipient(.init()))
            return .none
        }

        if let recipient = state.recipient, derivationTool.isDarkFiAddress(recipient, DarkfiNetwork.activeLabel) {
            var addMemoState = AddMemo.State(receiveAddress: state.receiveAddress)
            addMemoState.memoCharLimit = state.memoCharLimit
            state.path.append(Path.State.addMemo(addMemoState))
            return .none
        }

        guard let recipientAddr = state.recipient else { return .none }
        return proposeAndReviewEffect(state: state, recipientAddr: recipientAddr)
    }

    func handleOnAppear(state: inout State) -> Effect<Action> {
        state.memoCharLimit = 255
        state.preferredCurrency = userPreferencesStorage.fiatCurrency()
        state.showScanButton = !processInfo.isiOSAppOnMac()
        return .merge(
            .publisher {
                sdkSynchronizer.stateStream()
                    .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                    .map(SendFlow.Action.synchronizerStateChanged)
            }
            .cancellable(id: SyncStatusUpdatesID.timer, cancelInFlight: true),
            .send(.loadTokenBalances)
        )
    }

    func handleSendTransaction(state: inout State) -> Effect<Action> {
        guard !state.isSendingTransaction,
              let recipientStr = state.recipient else { return .none }

        do {
            state.isSendingTransaction = true
            let recipient = Utils.Recipient.address(recipientStr)
            var memo: Memo?
            if let memoStr = state.memo?.data, !memoStr.isEmpty {
                memo = try Memo(string: memoStr)
            }
            return .run { [state, memo] send in
                do {
                    await send(SendFlow.Action.sendTransactionInProgress)
                    let txn = try await sdkSynchronizer.sendTransaction(
                        (),
                        state.amountToSend,
                        recipient,
                        memo,
                        state.selectedTokenId
                    )
                    await send(SendFlow.Action.sendTransactionSuccess(TransactionState(from: txn)))
                } catch {
                    await send(SendFlow.Action.sendTransactionFailure(error.toDarkFiError().message))
                }
            }
        } catch {
            return .send(.sendTransactionFailure(error.toDarkFiError().message))
        }
    }
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
