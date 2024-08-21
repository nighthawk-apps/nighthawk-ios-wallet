//
//  Home+Transfer.swift
//  
//
//  Created by Matthew Watt on 9/14/23.
//

import ComposableArchitecture

extension Home {
    @ReducerBuilder<State, Action>
    func transferReducer() -> some ReducerOf<Home> {
        receiveDelegateReducer()
    }
    
    private func receiveDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .transfer(.destination(.presented(.receive(.delegate(delegateAction))))):
                state.transfer.destination = nil
                return .run { send in
                    // Slight delay to allow previous sheet to dismiss before presenting
                    try await clock.sleep(for: .seconds(0.005))
                    
                    switch delegateAction {
                    case .showAddresses:
                        await send(.wallet(.viewAddressesTapped))
                    case .showPartners:
                        await send(.transfer(.topUpWalletTapped))
                    }
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
