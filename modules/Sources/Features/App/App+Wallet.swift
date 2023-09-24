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
                case .shieldFunds:
                    return .none
                case .showAddresses:
                    return .none
                case .showTransactionHistory:
                    state.path.append(.transactionHistory())
                    return .none
                case let .showTransactionDetail(walletEvent):
                    state.path.append(.transactionDetail(.init(walletEvent: walletEvent, networkType: zcashNetwork.networkType)))
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .scenePhaseChanged, .splash:
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
                    // TODO: Handle disk full
                    return .none
                case let .showTransactionDetail(walletEvent):
                    state.path.append(.transactionDetail(.init(walletEvent: walletEvent, networkType: zcashNetwork.networkType)))
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .scenePhaseChanged, .splash:
                return .none
            }
        }
    }
}
