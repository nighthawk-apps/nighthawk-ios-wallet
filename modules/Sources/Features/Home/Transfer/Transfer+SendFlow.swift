//
//  Transfer+SendFlow.swift
//
//
//  Created by Matthew Watt on 9/27/23.
//

import ComposableArchitecture

extension Transfer {
    @ReducerBuilder<State, Action>
    func sendFlowReducer() -> some ReducerOf<Self> {
        sendFlowDelegate()
        scanDelegateReducer()
        sendSuccessDelegateReducer()
        sendFailedDelegateReducer()
    }
    
    private func sendFlowDelegate() -> Reduce<Transfer.State, Transfer.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.send(.delegate(delegateAction)))):
                switch delegateAction {
                case .showPartners:
                    state.destination = nil
                    return .run { send in
                        // Slight delay to allow previous sheet to dismiss before presenting
                        try await clock.sleep(for: .seconds(0.005))
                        await send(.topUpWalletTapped)
                    }
                }
            case .destination,
                 .receiveMoneyTapped,
                 .sendMoneyTapped,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
    
    private func scanDelegateReducer() -> Reduce<Transfer.State, Transfer.Action> {
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
            case .destination,
                 .receiveMoneyTapped,
                 .sendMoneyTapped,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
    
    private func sendSuccessDelegateReducer() -> Reduce<Transfer.State, Transfer.Action> {
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
            case .destination,
                 .receiveMoneyTapped,
                 .sendMoneyTapped,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
    
    private func sendFailedDelegateReducer() -> Reduce<Transfer.State, Transfer.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.send(.path(.element(id: _, action: .failed(.delegate(delegateAction))))))):
                switch delegateAction {
                case .cancelTransaction:
                    state.destination = nil
                    return .none
                }
            case .destination,
                 .receiveMoneyTapped,
                 .sendMoneyTapped,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
}
