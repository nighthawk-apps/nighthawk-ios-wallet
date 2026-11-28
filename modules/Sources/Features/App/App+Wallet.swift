//
//  App+Wallet.swift
//
//
//  Created by Matthew Watt on 9/15/23.
//

import ComposableArchitecture
import Home
import Models
import Utils

extension AppReducer {
    @ReducerBuilder<State, Action>
    func walletReducer() -> some ReducerOf<Self> {
        walletDelegateReducer()
        transactionHistoryDelegateReducer()
        transactionDetailDelegateReducer()
    }

    private func walletDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .home(.wallet(.delegate(delegateAction))))):
                switch delegateAction {
                case .scanPaymentRequest, .receiveMoney, .sendMoney, .sendToken, .requestMoney:
                    return .none
                case .sendAgain, .retryConnectionIfDisconnected:
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
                                networkType: DarkfiNetwork.activeLabel,
                                latestFiatPrice: state.latestFiatPrice
                            )
                        )
                    )
                    return .none
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess,
                .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess,
                .path, .scenePhaseChanged, .splash, .receiveAddressResponse:
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
                                networkType: DarkfiNetwork.activeLabel,
                                latestFiatPrice: state.latestFiatPrice
                            )
                        )
                    )
                    return .none
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess,
                .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess,
                .path, .scenePhaseChanged, .splash, .receiveAddressResponse:
                return .none
            }
        }
    }

    private func transactionDetailDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: detailId, action: .transactionDetail(.delegate(delegateAction)))):
                switch delegateAction {
                case .handleDiskFull:
                    state.alert = .notEnoughFreeDiskSpace()
                    return .none
                case let .sendAgain(recipient, amount):
                    state.path.pop(from: detailId)
                    if let homeId = state.path.ids.first(where: { id in
                        if case .home = state.path[id: id] { return true }
                        return false
                    }) {
                        return .send(
                            .path(
                                .element(
                                    id: homeId,
                                    action: .home(.wallet(.delegate(.sendAgain(recipient: recipient, amount: amount))))
                                )
                            )
                        )
                    }
                    return .none
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess,
                .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess,
                .path, .scenePhaseChanged, .splash, .receiveAddressResponse:
                return .none
            }
        }
    }
}
