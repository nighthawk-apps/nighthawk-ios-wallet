//
//  Home+Wallet.swift
//  stealth
//
//  DarkFi: No autoshield — all funds are always private.
//

import ComposableArchitecture
import Receive
import SendFlow

extension Home {
    @ReducerBuilder<State, Action>
    func walletReducer() -> some ReducerOf<Self> {
        walletDelegateReducer()
    }

    private func walletDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            guard case let .wallet(.delegate(delegateAction)) = action else {
                return .none
            }
            return handleWalletDelegate(delegateAction, state: &state)
        }
    }

    private func handleWalletDelegate(
        _ delegateAction: Wallet.Action.Delegate,
        state: inout Home.State
    ) -> Effect<Home.Action> {
        switch delegateAction {
        case .scanPaymentRequest:
            let sendState = makeSendState(
                from: state,
                path: StackState([.scan(.init(backButtonType: .close))]),
                showCloseButton: false,
                includeTokens: false
            )
            state.transfer.destination = .send(sendState)
        case .receiveMoney:
            state.transfer.destination = .receive(
                .init(
                    receiveAddress: state.walletInfo.receiveAddress,
                    showCloseButton: processInfo.isiOSAppOnMac()
                )
            )
        case .sendMoney:
            state.transfer.destination = .send(
                makeSendState(from: state, showCloseButton: processInfo.isiOSAppOnMac())
            )
        case let .sendToken(tokenId):
            var sendState = makeSendState(from: state, showCloseButton: true)
            sendState.selectedTokenId = tokenId
            state.transfer.destination = .send(sendState)
        case .requestMoney:
            state.transfer.destination = .request(
                .init(
                    address: state.walletInfo.receiveAddress?.stringEncoded ?? "",
                    showCloseButton: processInfo.isiOSAppOnMac()
                )
            )
        case .showAddresses:
            state.destination = .addresses(
                .init(
                    receiveAddress: state.walletInfo.receiveAddress,
                    showCloseButton: processInfo.isiOSAppOnMac()
                )
            )
        case .showTransactionDetail, .showTransactionHistory:
            break
        case let .sendAgain(recipient, amount):
            var sendState = makeSendState(from: state, showCloseButton: true, includeTokens: false)
            sendState.recipient = recipient
            if amount > 0 {
                sendState.amountToSendInput = amount.inputDecimalString()
            }
            state.transfer.destination = .send(sendState)
        }
        return .none
    }

    private func makeSendState(
        from state: Home.State,
        path: StackState<SendFlow.Path.State> = .init(),
        showCloseButton: Bool,
        includeTokens: Bool = true
    ) -> SendFlow.State {
        var sendState = SendFlow.State(
            path: path,
            latestFiatPrice: state.walletInfo.latestFiatPrice,
            showCloseButton: showCloseButton
        )
        sendState.spendableBalance = state.walletInfo.balance
        sendState.receiveAddress = state.walletInfo.receiveAddress
        if includeTokens {
            sendState.availableTokens = state.walletInfo.tokenBalances
        }
        return sendState
    }
}
