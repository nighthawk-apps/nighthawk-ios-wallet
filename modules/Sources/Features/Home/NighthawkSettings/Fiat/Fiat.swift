//
//  Fiat.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture

public struct Fiat: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    
    public var body: some ReducerOf<Self> {
        Reduce { _, _ in
            return .none
        }
    }
    
    public init() {}
}

// MARK: - Placeholder
extension Fiat.State {
    public static var placeholder = Self()
}
