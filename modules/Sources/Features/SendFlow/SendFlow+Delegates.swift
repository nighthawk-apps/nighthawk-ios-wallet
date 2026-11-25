//
//  SendFlow+Delegates.swift
//  SendFlow
//

import ComposableArchitecture
import DerivationTool
import Models
import SDKSynchronizer
import URIParser
import Utils

// MARK: - Shared proposal builder
extension SendFlow {
    func proposeAndReviewEffect(state: State, recipientAddr: String) -> Effect<Action> {
        .run { send in
            do {
                let recipient = Utils.Recipient.address(recipientAddr)
                let memo: Memo?
                if let memoText = state.memo?.data {
                    memo = memoText.isEmpty ? nil : try Memo(string: memoText)
                } else {
                    memo = nil
                }

                let proposal = try await sdkSynchronizer.proposeTransfer(
                    0,
                    recipient,
                    state.amountToSend,
                    memo,
                    state.selectedTokenId
                )

                if !state.customTokenFeeIsCovered(proposal) {
                    await send(.proposeSendTransactionFailure(
                        DarkfiError(message: "Not enough DRK to pay the fee")
                    ))
                    return
                }

                await send(.setProposal(proposal))
                await send(
                    .review(
                        .init(
                            zecAmount: state.amountToSend,
                            memo: state.memo,
                            recipient: recipientAddr,
                            latestFiatPrice: state.latestFiatPrice,
                            proposal: proposal,
                            tokenName: state.tokenName,
                            syncMethod: sdkSynchronizer.latestState().activeSyncMethod
                        )
                    )
                )
            } catch {
                await send(SendFlow.Action.proposeSendTransactionFailure(error.toDarkFiError()))
            }
        }
    }
}

// MARK: - Add memo delegate
extension SendFlow {
    func addMemoDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            guard case let .path(.element(id: id, action: .addMemo(.delegate(delegateAction)))) = action else {
                return .none
            }
            switch delegateAction {
            case .goBack:
                _ = state.path.popLast()
                return .none
            case .nextScreen:
                guard case let .addMemo(addMemoState) = state.path[id: id] else {
                    return .none
                }
                state.memo = if addMemoState.isIncludeReplyToChecked, let ua = state.receiveAddress?.stringEncoded {
                    "\(addMemoState.memo)\nReply to: \(ua)".redacted
                } else {
                    addMemoState.memo.redacted
                }

                if let recipientString = state.recipient {
                    return proposeAndReviewEffect(state: state, recipientAddr: recipientString)
                }
                state.path.append(.recipient(.init()))
                return .none
            }
        }
    }
}

// MARK: - Recipient delegate
extension SendFlow {
    func recipientDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            guard case let .path(.element(id: _, action: .recipient(.delegate(delegateAction)))) = action else {
                return .none
            }
            switch delegateAction {
            case .goBack:
                _ = state.path.popLast()
                return .none
            case let .proceedWithRecipient(recipient, amount, memo):
                guard derivationTool.isDarkFiAddress(recipient, DarkfiNetwork.activeLabel) else { return .none }
                state.recipient = recipient
                if let amount, !amount.isEmpty {
                    state.amountToSendInput = amount
                }
                if let memo, !memo.isEmpty {
                    state.memo = memo.redacted
                }
                var addMemoState = AddMemo.State(receiveAddress: state.receiveAddress)
                addMemoState.memoCharLimit = state.memoCharLimit
                if let memo, !memo.isEmpty {
                    addMemoState.memo = memo
                }
                state.path.append(Path.State.addMemo(addMemoState))
                return .none
            case .scanCode:
                state.path.append(Path.State.scan(.init()))
                return .none
            }
        }
    }
}

// MARK: - Scan delegate
extension SendFlow {
    func scanDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            guard case let .path(.element(id: _, action: .scan(.delegate(delegateAction)))) = action else {
                return .none
            }
            switch delegateAction {
            case .goHome:
                return .none
            case let .handleParseResult(result):
                return handleScanParseResult(result, state: &state)
            }
        }
    }

    private func handleScanParseResult(
        _ result: QRCodeParseResult,
        state: inout SendFlow.State
    ) -> Effect<SendFlow.Action> {
        if result.address.isEmpty, result.contactInvite != nil {
            _ = state.path.popLast()
            return .none
        }
        state.recipient = result.address
        state.amountToSendInput = result.amount ?? state.amountToSendInput
        state.memo = result.memo?.redacted
        _ = state.path.popLast()

        guard let address = state.recipient, !address.isEmpty else {
            return .none
        }
        if !state.hasEnteredAmount {
            state.path = StackState()
            return .none
        }
        if state.amountToSend > state.selectedSpendableBalance
            || (state.selectedTokenId != nil && state.spendableBalance <= .zero) {
            state.amountToSendInput = "0"
            state.recipient = nil
            state.memo = nil
            state.proposal = nil
            state.path = StackState()
            state.toast = .notEnoughDrk
            return .none
        }
        if state.memo == nil {
            var addMemoState = AddMemo.State(receiveAddress: state.receiveAddress)
            addMemoState.memoCharLimit = state.memoCharLimit
            state.path.append(Path.State.addMemo(addMemoState))
            return .none
        }
        return proposeAndReviewEffect(state: state, recipientAddr: address)
    }
}

// MARK: - Review delegate
extension SendFlow {
    func reviewDelegateReducer() -> Reduce<SendFlow.State, SendFlow.Action> {
        Reduce { state, action in
            guard case let .path(.element(id: _, action: .review(.delegate(delegateAction)))) = action else {
                return .none
            }
            switch delegateAction {
            case .goBack:
                _ = state.path.popLast()
                return .none
            case .sendDrk:
                return .send(.sendTransaction)
            }
        }
    }
}
