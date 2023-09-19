//
//  ChangeServer.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

public struct ChangeServer: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    
    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
    
    public init() {}
}

// MARK: - Placeholder
extension ChangeServer.State {
    public static let placeholder = Self()
}
