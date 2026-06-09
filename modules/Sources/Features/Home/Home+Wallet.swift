//
//  Home+Wallet.swift
//  stealth
//
//  DarkFi: No autoshield — all funds are always private.
//

import ComposableArchitecture

extension Home {
    @ReducerBuilder<State, Action>
    func walletReducer() -> some ReducerOf<Self> {
        walletDelegateReducer()
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
                 .chat,
                 .delegate,
                 .destination,
                 .fetchLatestFiatPrice,
                 .latestFiatResponse,
                 .listenForSynchronizerUpdates,
                 .onAppear,
                 .rescanDone,
                 .settings,
                 .synchronizerStateChanged,
                 .tabSelected,
                 .transfer,
                 .updateWalletEvents,
                 .wallet:
                return .none
            }
        }
    }
}
