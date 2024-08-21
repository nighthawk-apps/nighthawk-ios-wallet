//
//  WalletCreated.swift
//  secant
//
//  Created by Matthew Watt on 4/19/23.
//

import ComposableArchitecture
import FeedbackGenerator
import SubsonicClient

@Reducer
public struct WalletCreated {
    
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case backup
        case delegate(Delegate)
        case onAppear
        case skip
        
        public enum Delegate: Equatable {
            case initializeSDKAndLaunchWallet
            case backupSeedPhrase
        }
    }
    
    @Dependency(\.feedbackGenerator) var feedbackGenerator
    @Dependency(\.subsonic) var subsonic
        
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .backup:
                return .send(.delegate(.backupSeedPhrase))
            case .delegate:
                return .none
            case .onAppear:
                feedbackGenerator.generateSuccessFeedback()
                subsonic.play("sound_receive_small.mp3")
                return .none
            case .skip:
                return .send(.delegate(.initializeSDKAndLaunchWallet))
            }
        }
    }
    
    public init() {}
}
