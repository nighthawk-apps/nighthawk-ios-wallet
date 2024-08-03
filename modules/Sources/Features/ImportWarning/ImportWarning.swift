//
//  ImportWarning.swift
//
//
//  Created by Matthew Watt on 9/24/23.
//

import ComposableArchitecture

@Reducer
public struct ImportWarning {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case cancelTapped
        case delegate(Delegate)
        case proceedTapped
        
        public enum Delegate: Equatable {
            case goToImport
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .cancelTapped:
                return .run { _ in await self.dismiss() }
            case .delegate:
                return .none
            case .proceedTapped:
                return .send(.delegate(.goToImport))
            }
        }
    }
    
    public init() {}
}
