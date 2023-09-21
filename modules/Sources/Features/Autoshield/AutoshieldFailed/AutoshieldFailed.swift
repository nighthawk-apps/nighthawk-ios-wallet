//
//  AutoshieldFailed.swift
//
//
//  Created by Matthew Watt on 9/19/23.
//

import ComposableArchitecture

public struct AutoshieldFailed: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case backTapped
    }
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .backTapped:
                return .run { _ in await self.dismiss() }
            }
        }
    }
    
    public init() {}
}
