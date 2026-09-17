//
//  Welcome.swift
//  stealth
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
        public enum Mode: Equatable {
            /// Create / restore after Tor connecting.
            case getStarted
            /// Educational pages after first-time seed backup (or restore).
            case postBackupCarousel
        }

        @Presents public var destination: Destination.State?
        public var mode: Mode

        public init(mode: Mode = .getStarted) {
            self.mode = mode
        }
    }

    public enum Action: Equatable {
        case createNewWalletTapped
        case carouselFinished
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case importExistingWalletTapped
        case termsAndConditionsTapped

        public enum Delegate: Equatable {
            case createNewWallet
            case importExistingWallet
            case onboardingFinished
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
            case .carouselFinished:
                return .send(.delegate(.onboardingFinished))
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
                 .carouselFinished,
                 .delegate,
                 .destination,
                 .importExistingWalletTapped,
                 .termsAndConditionsTapped:
                return .none
            }
        }
    }
}
