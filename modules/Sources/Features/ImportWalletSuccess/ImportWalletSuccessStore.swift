//
//  ImportWalletSuccessStore.swift
//  secant
//
//  Created by Matthew Watt on 5/13/23.
//

import ComposableArchitecture
import FeedbackGenerator
import SubsonicClient

public struct ImportWalletSuccessReducer: ReducerProtocol {
    public struct State: Equatable {}
    
    public enum Action: Equatable {
        case viewWallet
        case generateSuccessFeedback
    }
    
    @Dependency(\.feedbackGenerator) var feedbackGenerator
    @Dependency(\.subsonic) var subsonic
    
    public init() {}
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, action in
            switch action {
            case .generateSuccessFeedback:
                feedbackGenerator.generateSuccessFeedback()
                subsonic.play("sound_receive_small.mp3")
                return .none
            case .viewWallet:
                return .none
            }
        }
    }
}

// MARK: - Placeholder
extension ImportWalletSuccessReducer.State {
    public static var placeholder = Self()
}
