//
//  App+Wallet.swift
//  
//
//  Created by Matthew Watt on 9/15/23.
//

import ComposableArchitecture
import Home
import Models

extension AppReducer {
    @ReducerBuilder<State, Action>
    func walletReducer() -> some ReducerOf<Self> {
        walletDelegateReducer()
        transactionHistoryDelegateReducer()
    }
    
    private func walletDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .home(.wallet(.delegate(delegateAction))))):
                switch delegateAction {
                case .scanPaymentRequest:
                    return .none
                case .shieldFunds:
                    return .none
                case .showAddresses:
                    return .none
                case let .showTransactionHistory(walletEvents):
                    state.path.append(
                        .transactionHistory(
                            .init(
                                latestFiatPrice: state.latestFiatPrice,
                                initialEvents: walletEvents
                            )
                        )
                    )
                    return .none
                case let .showTransactionDetail(walletEvent):
                    state.path.append(
                        .transactionDetail(
                            .init(
                                walletEvent: walletEvent,
                                networkType: zcashSDKEnvironment.network.networkType,
                                latestFiatPrice: state.latestFiatPrice
                            )
                        )
                    )
                    return .none
                }
            case .alert, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
    
    private func transactionHistoryDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .transactionHistory(.delegate(delegateAction)))):
                switch delegateAction {
                case .handleDiskFull:
                    state.alert = .notEnoughFreeDiskSpace()
                    return .none
                case let .showTransactionDetail(walletEvent):
                    state.path.append(
                        .transactionDetail(
                            .init(
                                walletEvent: walletEvent, 
                                networkType: zcashSDKEnvironment.network.networkType,
                                latestFiatPrice: state.latestFiatPrice
                            )
                        )
                    )
                    return .none
                }
            case .alert, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
}
