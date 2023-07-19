//
//  ExternalServicesStore.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

public struct ExternalServicesReducer: ReducerProtocol {
    public struct State: Equatable {}
    public enum Action: Equatable {}
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension ExternalServicesReducer.State {
    public static let placeholder = Self()
}
