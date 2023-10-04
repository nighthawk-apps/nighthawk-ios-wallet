//
//  Home+NighthawkSettings.swift
//
//
//  Created by Matthew Watt on 9/28/23.
//

import Combine
import ComposableArchitecture

extension Home {
    @ReducerBuilder<State, Action>
    func nighthawkSettingsReducer() -> some ReducerOf<Self> {
        nighthawkSettingsDelegateReducer()
    }
    
    private func nighthawkSettingsDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .settings(.delegate(delegateAction)):
                switch delegateAction {
                case .goTo:
                    return .none
                case .rescan:
                    return rescan()
                }
            case .binding,
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
    
    private func rescan() -> Effect<Action> {
        .publisher {
            sdkSynchronizer.rewind(.birthday)
                .replaceEmpty(with: Void())
                .map { _ in return Home.Action.rescanDone() }
                .catch { error in
                    return Just(Home.Action.rescanDone(error.toZcashError())).eraseToAnyPublisher()
                }
                .receive(on: mainQueue)
        }
        .cancellable(id: CancelId.timer, cancelInFlight: true)
    }
}
