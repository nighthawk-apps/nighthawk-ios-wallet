//
//  ImportWalletSuccess.swift
//  secant
//
//  Created by Matthew Watt on 5/13/23.
//

import ComposableArchitecture
import FeedbackGenerator
import SubsonicClient

@Reducer
public struct ImportWalletSuccess {
    
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case delegate(Delegate)
        case generateSuccessFeedback
        case viewWalletTapped
        
        public enum Delegate: Equatable {
            case initializeSDKAndLaunchWallet
        }
    }
    
    @Dependency(\.feedbackGenerator) var feedbackGenerator
    @Dependency(\.subsonic) var subsonic
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case .generateSuccessFeedback:
                feedbackGenerator.generateSuccessFeedback()
                subsonic.play("sound_receive_small.mp3")
                return .none
            case .viewWalletTapped:
                return .send(.delegate(.initializeSDKAndLaunchWallet))
            }
        }
    }
}
