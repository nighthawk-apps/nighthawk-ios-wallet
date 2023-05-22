//
//  AboutStore.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

struct AboutReducer: ReducerProtocol {
    struct State: Equatable {}
    enum Action: Equatable {}
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension AboutReducer.State {
    static let placeholder = Self()
}
