//
//  TransactionHistory.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import ComposableArchitecture
import Models

public struct TransactionHistory: ReducerProtocol {
    public struct State: Equatable {
        public var walletEvents: IdentifiedArrayOf<WalletEvent>
        
        public init(walletEvents: IdentifiedArrayOf<WalletEvent>) {
            self.walletEvents = walletEvents
        }
    }
    
    public enum Action: Equatable {}
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
    
    public init() {}
}
