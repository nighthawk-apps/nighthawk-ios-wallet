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
            switch action {
            case let .wallet(.delegate(delegateAction)):
                switch delegateAction {
                case .scanPaymentRequest:
                    state.transfer.destination = .send(
                        .init(
                            path: StackState([.scan(.init(backButtonType: .close))]),
                            latestFiatPrice: state.walletInfo.latestFiatPrice
                        )
                    )
                    return .none
                case .receiveMoney:
                    state.transfer.destination = .receive(
                        .init(
                            uAddress: state.walletInfo.unifiedAddress,
                            showCloseButton: processInfo.isiOSAppOnMac()
                        )
                    )
                    return .none
                case .sendMoney:
                    var sendState = SendFlow.State(
                        latestFiatPrice: state.walletInfo.latestFiatPrice,
                        showCloseButton: processInfo.isiOSAppOnMac()
                    )
                    sendState.spendableBalance = state.walletInfo.balance
                    sendState.unifiedAddress = state.walletInfo.unifiedAddress
                    state.transfer.destination = .send(sendState)
                    return .none
                case .requestMoney:
                    state.transfer.destination = .request(
                        .init(
                            address: state.walletInfo.unifiedAddress?.stringEncoded ?? "",
                            showCloseButton: processInfo.isiOSAppOnMac()
                        )
                    )
                    return .none
                case .showAddresses:
                    state.destination = .addresses(
                        .init(
                            uAddress: state.walletInfo.unifiedAddress,
                            showCloseButton: processInfo.isiOSAppOnMac()
                        )
                    )
                    return .none
                case .showTransactionDetail:
                    return .none
                case .showTransactionHistory:
                    return .none
                case let .sendAgain(recipient, amount):
                    var sendState = SendFlow.State(
                        latestFiatPrice: state.walletInfo.latestFiatPrice,
                        showCloseButton: true
                    )
                    sendState.spendableBalance = state.walletInfo.balance
                    sendState.unifiedAddress = state.walletInfo.unifiedAddress
                    sendState.recipient = recipient
                    if amount > 0 {
                        sendState.amountToSendInput = amount.inputDecimalString()
                    }
                    state.transfer.destination = .send(sendState)
                    return .none
                }
            case .alert,
                 .binding,
                 .cancelSynchronizerUpdates,
                 .cantStartSync,
                 .chat,
                 .delegate,
                 .destination,
                 .fetchLatestFiatPrice,
                 .daoHub,
                 .latestFiatResponse,
                 .listenForSynchronizerUpdates,
                 .onAppear,
                 .rescanDone,
                 .settings,
                 .synchronizerStateChanged,
                 .tabSelected,
                 .transfer,
                 .updateWalletEvents,
                 .unifiedAddressLoaded,
                 .wallet:
                return .none
            }
        }
    }
}
