//
//  TransferStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture

public typealias TransferStore = Store<TransferReducer.State, TransferReducer.Action>
public typealias TransferViewStore = ViewStore<TransferReducer.State, TransferReducer.Action>

public struct TransferReducer: ReducerProtocol {
    public struct State: Equatable {}
    
    public enum Action: Equatable {
        case noop
    }
    
    public var body: some ReducerProtocol<State, Action> {
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
    public static var placeholder: Self {
        .init()
    }
}
