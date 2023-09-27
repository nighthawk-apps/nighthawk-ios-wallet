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

public struct Welcome: Reducer {
    public struct State: Equatable {
        @PresentationState public var destination: Destination.State?
        
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
    
    public struct Destination: Reducer {
        public enum State: Equatable {
            case importSeedWarningAlert(ImportWarning.State)
        }
        
        public enum Action: Equatable {
            case importSeedWarningAlert(ImportWarning.Action)
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.importSeedWarningAlert, action: /Action.importSeedWarningAlert) {
                ImportWarning()
            }
        }
        
        public init() {}
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
                // TODO: Open terms
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
        
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
