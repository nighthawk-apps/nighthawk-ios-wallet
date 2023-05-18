//
//  SecurityReducer.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture

struct SecurityReducer: ReducerProtocol {
    struct State: Equatable {}
    enum Action: Equatable {}
    
    var body: some ReducerProtocol<SecurityReducer.State, SecurityReducer.Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension SecurityReducer.State {
    static var placeholder = Self()
}
