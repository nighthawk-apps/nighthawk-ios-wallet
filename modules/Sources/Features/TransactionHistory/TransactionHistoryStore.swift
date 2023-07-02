//
//  TransactionHistoryStore.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import ComposableArchitecture
import Models

public struct TransactionHistoryReducer: ReducerProtocol {
    public struct State: Equatable {
        public var walletEvents: IdentifiedArrayOf<WalletEvent>
    }
    
    public enum Action: Equatable {}
    
    public init() {}
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension TransactionHistoryReducer.State {
    public static var placeholder: Self {
        .init(walletEvents: .placeholder)
    }
}

