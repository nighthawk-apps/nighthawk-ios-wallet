//
//  NHWalletCreatedStore.swift
//  secant
//
//  Created by Matthew Watt on 4/19/23.
//

import ComposableArchitecture
import FeedbackGenerator
import SubsonicClient

public typealias WalletCreatedStore = Store<WalletCreatedReducer.State, WalletCreatedReducer.Action>

public struct WalletCreatedReducer: ReducerProtocol {
    public struct State: Equatable {}
    
    public enum Action: Equatable {
        case backup
        case onAppear
        case skip
    }
    
    @Dependency(\.feedbackGenerator) var feedbackGenerator
    @Dependency(\.subsonic) var subsonic
    
    public init() {}
    
    public var body: some ReducerProtocol<State, Action> {
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

extension WalletCreatedReducer.State {
    public static let placeholder = WalletCreatedReducer.State()
}

extension WalletCreatedStore {
    public static let placeholder = WalletCreatedStore(
        initialState: .placeholder,
        reducer: WalletCreatedReducer()
    )
}
