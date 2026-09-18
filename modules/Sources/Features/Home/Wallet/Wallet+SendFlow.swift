//
//  Wallet+SendFlow.swift
//  stealth
//

import ComposableArchitecture

extension Wallet {
    @ReducerBuilder<State, Action>
    func sendFlowReducer() -> some ReducerOf<Self> {
        scanDelegateReducer()
        sendSuccessDelegateReducer()
        sendFailedDelegateReducer()
    }

    private func scanDelegateReducer() -> Reduce<Wallet.State, Wallet.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.send(.path(.element(id: _, action: .scan(.delegate(delegateAction))))))):
                switch delegateAction {
                case .goHome:
                    state.destination = nil
                    return .none
                case .handleParseResult:
                    return .none
                }
            case .binding,
                 .delegate,
                 .destination,
                 .onAppear,
                 .receiveMoneyTapped,
                 .requestMoneyTapped,
                 .scanPaymentRequestTapped,
                 .sendMoneyTapped,
                 .sendTokenTapped,
                 .tokenBalancesLoaded,
                 .viewAddressesTapped,
                 .viewTransactionDetailTapped,
                 .viewTransactionHistoryTapped:
                return .none
            }
        }
    }

    private func sendSuccessDelegateReducer() -> Reduce<Wallet.State, Wallet.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.send(.path(.element(id: _, action: .success(.delegate(delegateAction))))))):
                switch delegateAction {
                case .goHome:
                    state.destination = nil
                    return .none
                case .showTransactionDetails:
                    state.destination = nil
                    return .none
                }
            case .binding,
                 .delegate,
                 .destination,
                 .onAppear,
                 .receiveMoneyTapped,
                 .requestMoneyTapped,
                 .scanPaymentRequestTapped,
                 .sendMoneyTapped,
                 .sendTokenTapped,
                 .tokenBalancesLoaded,
                 .viewAddressesTapped,
                 .viewTransactionDetailTapped,
                 .viewTransactionHistoryTapped:
                return .none
            }
        }
    }

    private func sendFailedDelegateReducer() -> Reduce<Wallet.State, Wallet.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.send(.path(.element(id: _, action: .failed(.delegate(delegateAction))))))):
                switch delegateAction {
                case .cancelTransaction:
                    state.destination = nil
                    return .none
                }
            case .binding,
                 .delegate,
                 .destination,
                 .onAppear,
                 .receiveMoneyTapped,
                 .requestMoneyTapped,
                 .scanPaymentRequestTapped,
                 .sendMoneyTapped,
                 .sendTokenTapped,
                 .tokenBalancesLoaded,
                 .viewAddressesTapped,
                 .viewTransactionDetailTapped,
                 .viewTransactionHistoryTapped:
                return .none
            }
        }
    }
}
