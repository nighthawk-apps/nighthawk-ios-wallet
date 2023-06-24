//
//  ChangeServerStore.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

struct ChangeServerReducer: ReducerProtocol {
    struct State: Equatable {}
    enum Action: Equatable {}
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension ChangeServerReducer.State {
    static let placeholder = Self()
}
