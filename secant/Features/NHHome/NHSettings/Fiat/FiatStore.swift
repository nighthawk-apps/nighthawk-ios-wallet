//
//  FiatStore.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture

struct FiatReducer: ReducerProtocol {
    struct State: Equatable {}
    enum Action: Equatable {}
    
    var body: some ReducerProtocol<FiatReducer.State, FiatReducer.Action> {
        Reduce { _, _ in
            return .none
        }
    }
}

// MARK: - Placeholder
extension FiatReducer.State {
    static var placeholder = Self()
}
