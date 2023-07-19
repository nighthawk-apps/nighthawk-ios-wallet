//
//  SecurityReducer.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture

public struct SecurityReducer: ReducerProtocol {
    public struct State: Equatable {}
    public enum Action: Equatable {}
    
    public var body: some ReducerProtocol<SecurityReducer.State, SecurityReducer.Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension SecurityReducer.State {
    public static var placeholder = Self()
}
