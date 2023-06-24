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
        case onAppear
        case skip
    }
    
    @Dependency(\.feedbackGenerator) var feedbackGenerator
    @Dependency(\.subsonic) var subsonic
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { _, action in
            switch action {
            case .onAppear:
                feedbackGenerator.generateSuccessFeedback()
                subsonic.play("sound_receive_small.mp3")
                return .none
            case .backup, .skip:
                return .none
            }
        }
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
