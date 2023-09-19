//
//  Failed.swift
//  
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture

public struct Failed: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case cancelTapped
        case delegate(Delegate)
        case tryAgainTapped
        
        public enum Delegate: Equatable {
            case cancelTransaction
        }
    }
    
    public init() {}
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .backButtonTapped, .tryAgainTapped:
                return .run { _ in await self.dismiss() }
            case .cancelTapped:
                return .send(.delegate(.cancelTransaction))
            case .delegate:
                return .none
            }
        }
    }
}
