//
//  BackupStore.swift
//  secant
//
//  Created by Matthew Watt on 5/16/23.
//

import ComposableArchitecture

struct BackupReducer: ReducerProtocol {
    struct State: Equatable {}
    enum Action: Equatable {}
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension BackupReducer.State {
    static let placeholder = Self()
}
