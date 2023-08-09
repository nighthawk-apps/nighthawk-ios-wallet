//
//  FiatStore.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture

public struct FiatReducer: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    
    public var body: some ReducerProtocol<FiatReducer.State, FiatReducer.Action> {
        Reduce { _, _ in
            return .none
        }
    }
}

// MARK: - Placeholder
extension FiatReducer.State {
    public static var placeholder = Self()
}
