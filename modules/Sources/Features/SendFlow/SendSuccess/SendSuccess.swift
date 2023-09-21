//
//  SendSuccess.swift
//
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture

public struct SendSuccess: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case delegate(Delegate)
        case doneTapped
        case moreDetailsTapped
        
        public enum Delegate: Equatable {
            case goHome
        }
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case .doneTapped:
                return .send(.delegate(.goHome))
            case .moreDetailsTapped:
                // TODO: show tx details
                return .none
            }
        }
    }
}
