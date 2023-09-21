//
//  AutoshieldSuccess.swift
//
//
//  Created by Matthew Watt on 9/19/23.
//

import ComposableArchitecture

public struct AutoshieldSuccess: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case delegate(Delegate)
        case doneTapped
        
        public enum Delegate: Equatable {
            case goHome
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case .doneTapped:
                return .send(.delegate(.goHome))
            }
        }
    }
    
    public init() {}
}
