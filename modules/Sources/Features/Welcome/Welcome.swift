//
//  Welcome.swift
//  secant-testnet
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import Foundation
import Generated

public struct Welcome: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case createNewWalletTapped
        case delegate(Delegate)
        case importExistingWalletTapped
        case termsAndConditionsTapped
        
        public enum Delegate: Equatable {
            case createNewWallet
            case importExistingWallet
        }
    }
    
    public var body: some ReducerProtocolOf<Self> {
        Reduce { _, action in
            switch action {
            case .createNewWalletTapped:
                return .run { send in await send(.delegate(.createNewWallet)) }
            case .delegate:
                return .none
            case .importExistingWalletTapped:
                return .run { send in await send(.delegate(.importExistingWallet)) }
            case .termsAndConditionsTapped:
                // TODO: Open terms
                return .none
            }
        }
    }
    
    public init() {}
}
