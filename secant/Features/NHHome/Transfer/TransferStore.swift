//
//  TransferStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture

struct TransferReducer: ReducerProtocol {
    struct State: Equatable {}
    
    enum Action: Equatable {
        case noop
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { _, action in
            switch action {
            case .noop:
                return .none
            }
        }
    }
}

// MARK: - Placeholder
extension TransferReducer.State {
    static var placeholder: Self {
        .init()
    }
}
