//
//  Welcome.swift
//  secant-testnet
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import Foundation
import Generated
import ImportWarning
import UIKit

@Reducer
public struct Welcome {
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case createNewWalletTapped
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case importExistingWalletTapped
        case termsAndConditionsTapped
        
        public enum Delegate: Equatable {
            case createNewWallet
            case importExistingWallet
        }
    }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case importSeedWarningAlert(ImportWarning)
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .createNewWalletTapped:
                return .send(.delegate(.createNewWallet))
            case .delegate:
                return .none
            case .destination:
                return .none
            case .importExistingWalletTapped:
                state.destination = .importSeedWarningAlert(.init())
                return .none
            case .termsAndConditionsTapped:
                UIApplication.shared.open(.terms, options: [:], completionHandler: nil)
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        importWarningDelegateReducer()
    }
    
    public init() {}
}

// MARK: - Import warning delegate
extension Welcome {
    func importWarningDelegateReducer() -> Reduce<Welcome.State, Welcome.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.importSeedWarningAlert(.delegate(delegateAction)))):
                switch delegateAction {
                case .goToImport:
                    state.destination = nil
                    return .send(.delegate(.importExistingWallet))
                }
            case .createNewWalletTapped,
                 .delegate,
                 .destination,
                 .importExistingWalletTapped,
                 .termsAndConditionsTapped:
                return .none
            }
        }
    }
}
