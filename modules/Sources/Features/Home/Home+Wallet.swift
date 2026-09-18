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
        receiveDelegateReducer()
    }

    private func walletDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .wallet(.delegate(delegateAction)):
                switch delegateAction {
                case .showAddresses:
                    state.destination = .addresses(
                        .init(
                            uAddress: state.walletInfo.unifiedAddress,
                            showCloseButton: processInfo.isiOSAppOnMac()
                        )
                    )
                    return .none
                case .showTransactionDetail(_):
                    return .none
                case .showTransactionHistory(_):
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
                 .updateWalletEvents,
                 .wallet:
                return .none
            }
        }
    }

    private func receiveDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .wallet(.destination(.presented(.receive(.delegate(delegateAction))))):
                state.wallet.destination = nil
                switch delegateAction {
                case .showAddresses:
                    return .run { send in
                        // Slight delay to allow previous sheet to dismiss before presenting
                        try await clock.sleep(for: .seconds(0.005))
                        await send(.wallet(.viewAddressesTapped))
                    }
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
                 .updateWalletEvents,
                 .wallet:
                return .none
            }
        }
    }
}
