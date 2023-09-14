//
//  Home+Wallet.swift
//  
//
//  Created by Matthew Watt on 9/13/23.
//

import ComposableArchitecture

extension Home {
    @ReducerBuilder<State, Action>
    func walletReducer() -> some ReducerProtocolOf<Self> {
        walletDelegateReducer()
    }
    
    private func walletDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .wallet(.delegate(delegateAction)):
                switch delegateAction {
                case .showTransactionHistory:
                    return .none
                case .showAddresses:
                    state.addresses = .init()
                    return .none
                }
            case .addresses,
                 .binding,
                 .onAppear,
                 .onDisappear,
                 .settings,
                 .synchronizerStateChanged,
                 .transfer,
                 .updateWalletEvents,
                 .wallet:
                return .none
            }
        }
    }
}
