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
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
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
                    state.path = StackState(
                        state.path.map { state in
                            if case let .home(homeState) = state {
                                homeState.walletInfo.latestFiatPrice = nil
                                return Path.State.home(homeState)
                            }

                            return state
                        }
                    )
                    return .none
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
    
    private func advancedSettingsDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { _, action in
            switch action {
            case let .path(.element(id: _, action: .advanced(.delegate(delegateAction)))):
                switch delegateAction {
                case .deleteWallet:
                    return deleteWallet()
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
    
    private func aboutDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { _, action in
            switch action {
            case let .path(.element(id: _, action: .about(.delegate(delegateAction)))):
                switch delegateAction {
                case .showLicensesList:
                    // TODO: Show license list
                    return .none
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
    
    private func goTo(screen: NighthawkSettings.State.Screen, state: inout State) -> Effect<Action> {
        switch screen {
        case .about:
            state.path.append(.about(.init()))
            return .none
        case .advanced:
            state.path.append(.advanced(.init()))
            return .none
        case .backup:
            state.path.append(.backup(.init(flow: .settings)))
            return .none
        case .changeServer:
            state.path.append(.changeServer(.init()))
            return .none
        case .chatSettings:
            // TODO: Wire ChatSettings path destination
            return .none
        case .daoHub:
            // TODO: Wire DaoHub path destination
            return .none
        case .externalServices:
            state.path.append(.externalServices(.init()))
            return .none
        case .fiat:
            state.path.append(.fiat(.init()))
            return .none
        case .notifications:
            state.path.append(.notifications(.init()))
            return .none
        case .rescan:
            return .none
        case .security:
            state.path.append(.security(.init()))
            return .none
        case .torNetwork:
            // TODO: Wire TorNetwork path destination
            return .none
        }
    }
    
    private func deleteWallet() -> Effect<Action> {
        .run { send in
            do {
                try await sdkSynchronizer.wipe()
                await send(.deleteWalletSuccess)
            } catch {
                await send(.deleteWalletFailed)
            }
        }
        .cancellable(id: CancelId.timer, cancelInFlight: true)
    }
}
