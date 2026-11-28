//
//  Home+Chat.swift
//
//  Forwards chat chrome actions (settings / request) out of the Chat tab.
//

import ComposableArchitecture
import Models
import Receive
import SendFlow
import Utils

extension Home {
    @ReducerBuilder<State, Action>
    func chatReducer() -> some ReducerOf<Self> {
        chatDelegateReducer()
    }

    private func chatDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case .transfer(.destination(.presented(.send(.sendTransactionSuccess)))):
                if let ready = ChatReceiptBook.consumeReadyToPost() {
                    return .send(.chat(.postBroadcastedReceipt(ready.receipt, channel: ready.targetChannel)))
                }
                return .none
            case .transfer(.destination(.dismiss)),
                .transfer(.destination(.presented(.send(.closeButtonTapped)))),
                .transfer(.destination(.presented(.send(.path(.element(id: _, action: .failed(.delegate(.cancelTransaction)))))))):
                ChatReceiptBook.clearPending()
                return .none
            case let .chat(.delegate(delegateAction)):
                switch delegateAction {
                case .openChatSettings:
                    return .send(.delegate(.openChatSettings))
                case .requestMoney:
                    state.transfer.destination = .request(
                        .init(
                            address: state.walletInfo.receiveAddress?.stringEncoded ?? "",
                            showCloseButton: processInfo.isiOSAppOnMac()
                        )
                    )
                    return .none
                case let .payInvoice(address, amount, memo):
                    var sendState = SendFlow.State(
                        latestFiatPrice: state.walletInfo.latestFiatPrice,
                        showCloseButton: processInfo.isiOSAppOnMac()
                    )
                    sendState.spendableBalance = state.walletInfo.balance
                    sendState.receiveAddress = state.walletInfo.receiveAddress
                    sendState.recipient = address
                    if let amount, !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        sendState.amountToSendInput = amount
                    }
                    if let memo, !memo.isEmpty {
                        sendState.memo = memo.redacted
                    }
                    state.transfer.destination = .send(sendState)
                    return .none
                }
            case .alert,
                .autoRetryCompleted,
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
                .tokenBalancesLoaded,
                .receiveAddressLoaded,
                .wallet:
                return .none
            }
        }
    }
}
