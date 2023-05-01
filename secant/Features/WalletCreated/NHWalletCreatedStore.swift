//
//  NHWalletCreatedStore.swift
//  secant
//
//  Created by Matthew Watt on 4/19/23.
//

import ComposableArchitecture

typealias NHWalletCreatedStore = Store<NHWalletCreatedReducer.State, NHWalletCreatedReducer.Action>

struct NHWalletCreatedReducer: ReducerProtocol {
    struct State: Equatable {}
    
    enum Action: Equatable {
        case backup
        case skip
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholders

extension NHWalletCreatedReducer.State {
    static let placeholder = NHWalletCreatedReducer.State()
}

extension NHWalletCreatedStore {
    static let placeholder = NHWalletCreatedStore(
        initialState: .placeholder,
        reducer: NHWalletCreatedReducer()
    )
}
