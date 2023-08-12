//
//  RescanStore.swift
//  secant
//
//  Created by Matthew Watt on 5/16/23.
//

import ComposableArchitecture

public struct RescanReducer: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension RescanReducer.State {
    public static let placeholder = Self()
}
