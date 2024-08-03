//
//  SendSuccess.swift
//
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture
import Models

@Reducer
public struct SendSuccess {
    public struct State: Equatable {
        public var transaction: TransactionState
        
        public init(transaction: TransactionState) {
            self.transaction = transaction
        }
    }
    
    public enum Action: Equatable {
        case delegate(Delegate)
        case doneTapped
        case moreDetailsTapped
        
        public enum Delegate: Equatable {
            case goHome
            case showTransactionDetails(WalletEvent)
        }
    }
        
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .doneTapped:
                return .send(.delegate(.goHome))
            case .moreDetailsTapped:
                let event = WalletEvent(transaction: state.transaction)
                return .send(.delegate(.showTransactionDetails(event)))
            }
        }
    }
    
    public init() {}
}
