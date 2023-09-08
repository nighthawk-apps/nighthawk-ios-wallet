//
//  FailedStore.swift
//  
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture

public typealias FailedStore = Store<FailedReducer.State, FailedReducer.Action>

public struct FailedReducer: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case cancelTapped
        case tryAgainTapped
    }
    
    public init() {}
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, action in
            switch action {
            case .backButtonTapped, .tryAgainTapped:
                return .run { _ in await self.dismiss() }
            case .cancelTapped:
                return .none
            }
        }
    }
}
