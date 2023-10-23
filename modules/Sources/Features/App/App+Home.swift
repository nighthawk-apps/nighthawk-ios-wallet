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
                        state.unifiedAddress = unifiedAddress
                    }
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
}
