//
//  App+Settings.swift
//  
//
//  Created by Matthew Watt on 9/12/23.
//

import ComposableArchitecture
import Home
import Models

extension AppReducer {
    @ReducerBuilder<State, Action>
    func settingsReducer() -> some ReducerOf<Self> {
        nighthawkSettingsDelegateReducer()
        fiatDelegateReducer()
        advancedSettingsDelegateReducer()
        aboutDelegateReducer()
    }
    
    private func nighthawkSettingsDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .home(.settings(.delegate(delegateAction))))):
                switch delegateAction {
                case let .goTo(screen):
                    return goTo(screen: screen, state: &state)
                case .rescan:
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
    
    private func fiatDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .fiat(.delegate(delegateAction)))):
                switch delegateAction {
                case .fetchLatestFiatCurrency:
                    state.path =  StackState(
                        state.path.map { state in
                            if case var .home(homeState) = state {
                                homeState.latestFiatPrice = nil
                                return Path.State.home(homeState)
                            }

                            return state
                        }
                    )
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
    
    private func advancedSettingsDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .advanced(.delegate(delegateAction)))):
                switch delegateAction {
                case .deleteWallet:
                    return deleteWallet()
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
    
    private func aboutDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .about(.delegate(delegateAction)))):
                switch delegateAction {
                case .showLicensesList:
                    // TODO: Show license list
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
    
    private func goTo(screen: NighthawkSettings.State.Screen, state: inout State) -> Effect<Action> {
        switch screen {
        case .about:
            state.path.append(.about())
            return .none
        case .advanced:
            state.path.append(.advanced())
            return .none
        case .backup:
            state.path.append(.backup(.init(flow: .settings)))
            return .none
        case .changeServer:
            state.path.append(.changeServer())
            return .none
        case .externalServices:
            state.path.append(.externalServices())
            return .none
        case .fiat:
            state.path.append(.fiat())
            return .none
        case .notifications:
            state.path.append(.notifications())
            return .none
        case .rescan:
            return .none
        case .security:
            state.path.append(.security())
            return .none
        }
    }
    
    private func deleteWallet() -> Effect<Action> {
        guard let wipePublisher = sdkSynchronizer.wipe() else {
            return .send(.deleteWalletFailed)
        }
        
        return .publisher {
            wipePublisher
                .replaceEmpty(with: Void())
                .map { _ in return AppReducer.Action.deleteWalletSuccess }
                .replaceError(with: AppReducer.Action.deleteWalletFailed)
                .receive(on: mainQueue)
        }
        .cancellable(id: CancelId.timer, cancelInFlight: true)
    }
}
