//
//  TransactionHistoryStore.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import ComposableArchitecture
import Models

struct TransactionHistoryReducer: ReducerProtocol {
    struct State: Equatable {
        var walletEvents: IdentifiedArrayOf<WalletEvent>
    }
    
    enum Action: Equatable {}
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension TransactionHistoryReducer.State {
    static var placeholder: Self {
        .init(walletEvents: .placeholder)
    }
}

