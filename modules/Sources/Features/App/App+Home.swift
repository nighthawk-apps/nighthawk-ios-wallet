//
//  App+Home.swift
//
//
//  Created by Matthew Watt on 10/7/23.
//

import ComposableArchitecture
import Models

extension AppReducer {
    func homeDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .home(.delegate(delegateAction)))):
                switch delegateAction {
                case let .setLatestFiatPrice(latest):
                    state.latestFiatPrice = latest
                    return .none
                case let .unifiedAddressResponse(unifiedAddress):
                    if let unifiedAddress {
                        state.propagateUnifiedAddress(unifiedAddress)
                    }
                    return .none
                case .openDaoHub:
                    // Prefer the Groups tab over a pushed stack screen.
                    state.path = StackState(
                        state.path.map { element in
                            if case var .home(homeState) = element {
                                homeState.selectedTab = .daoHub
                                return .home(homeState)
                            }
                            return element
                        }
                    )
                    return .none
                case .openChatSettings:
                    state.path.append(.chatSettings(.init()))
                    return .none
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
}
