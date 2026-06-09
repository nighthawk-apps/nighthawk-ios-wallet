//
//  Home+NighthawkSettings.swift
//
//
//  Created by Matthew Watt on 9/28/23.
//

import Combine
import ComposableArchitecture
import Utils

extension Home {
    @ReducerBuilder<State, Action>
    func nighthawkSettingsReducer() -> some ReducerOf<Self> {
        nighthawkSettingsDelegateReducer()
    }
    
    private func nighthawkSettingsDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { _, action in
            switch action {
            case let .settings(.delegate(delegateAction)):
                switch delegateAction {
                case .goTo:
                    return .none
                case .rescan:
                    return rescan()
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
    
    private func rescan() -> Effect<Action> {
        .publisher {
            sdkSynchronizer.rewind()
                .replaceEmpty(with: Void())
                .map { _ in return Home.Action.rescanDone() }
                .catch { error in
                    return Just(Home.Action.rescanDone(error.toDarkFiError())).eraseToAnyPublisher()
                }
                .receive(on: mainQueue)
        }
        .cancellable(id: CancelId.timer, cancelInFlight: true)
    }
}
