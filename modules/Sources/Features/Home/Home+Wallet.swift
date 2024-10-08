//
//  Home+Wallet.swift
//  
//
//  Created by Matthew Watt on 9/13/23.
//

import ComposableArchitecture

extension Home {
    @ReducerBuilder<State, Action>
    func walletReducer() -> some ReducerOf<Self> {
        walletDelegateReducer()
        autoshieldSuccessDelegateReducer()
    }
    
    private func walletDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .wallet(.delegate(delegateAction)):
                switch delegateAction {
                case .scanPaymentRequest:
                    state.selectedTab = .transfer
                    state.transfer.destination = .send(
                        .init(
                            path: StackState([.scan(.init(backButtonType: .close))]),
                            latestFiatPrice: state.walletInfo.latestFiatPrice
                        )
                    )
                    return .none
                case .shieldFunds:
                    state.destination = .autoshield(.init())
                    return .none
                case .showAddresses:
                    state.destination = .addresses(
                        .init(
                            uAddress: state.walletInfo.unifiedAddress,
                            showCloseButton: processInfo.isiOSAppOnMac()
                        )
                    )
                    return .none
                case .showTransactionDetail:
                    return .none
                case .showTransactionHistory:
                    return .none
                }
            case .alert,
                 .binding,
                 .cancelSynchronizerUpdates,
                 .cantStartSync,
                 .delegate,
                 .destination,
                 .fetchLatestFiatPrice,
                 .latestFiatResponse,
                 .listenForSynchronizerUpdates,
                 .onAppear,
                 .rescanDone,
                 .settings,
                 .synchronizerStateChanged,
                 .transfer,
                 .updateWalletEvents,
                 .wallet:
                return .none
            }
        }
    }
    
    private func autoshieldSuccessDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.autoshield(.path(.element(id: _, action: .success(.delegate(delegateAction))))))):
                switch delegateAction {
                case .goHome:
                    state.destination = nil
                    return .none
                case .updateTransparentBalance:
                    state.walletInfo.transparentBalance = sdkSynchronizer.latestState().accountBalance?.unshielded ?? .zero
                    return .none
                }
            case .alert,
                 .binding,
                 .cancelSynchronizerUpdates,
                 .cantStartSync,
                 .delegate,
                 .destination,
                 .fetchLatestFiatPrice,
                 .latestFiatResponse,
                 .listenForSynchronizerUpdates,
                 .onAppear,
                 .rescanDone,
                 .settings,
                 .synchronizerStateChanged,
                 .transfer,
                 .updateWalletEvents,
                 .wallet:
                return .none
            }
        }
    }
}
