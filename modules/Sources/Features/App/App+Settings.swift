//
//  App+Settings.swift
//
//
//  Created by Matthew Watt on 9/12/23.
//

import ComposableArchitecture
import Home
import Models
import SDKSynchronizer
import WalletStorage

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
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
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
                        state.path.map { element in
                            if case let .home(homeState) = element {
                                var updated = homeState
                                updated.walletInfo.latestFiatPrice = nil
                                return Path.State.home(updated)
                            }

                            return element
                        }
                    )
                    // Re-fetch CoinGecko price for the newly selected currency.
                    if let id = state.path.ids.first(where: { id in
                        if case .home = state.path[id: id] { return true }
                        return false
                    }) {
                        return .send(.path(.element(id: id, action: .home(.fetchLatestFiatPrice))))
                    }
                    return .none
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
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
                case .nukeLocalDatabases:
                    return nukeLocalDatabases()
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
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
                    // Licenses are displayed inline in AboutView
                    return .none
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
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
            state.path.append(.chatSettings(.init()))
            return .none
        case .daoHub:
            state.path.append(.daoHub(.init()))
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
            state.path.append(.torNetwork(.init()))
            return .none
        }
    }

    private func deleteWallet() -> Effect<Action> {
        .run { send in
            do {
                // Full wipe: release handle, delete on-disk DBs, then drop seed.
                try await sdkSynchronizer.nukeLocalDatabases()
                DrkWalletPassStore.clear()
                await send(.deleteWalletSuccess)
            } catch {
                await send(.deleteWalletFailed)
            }
        }
        .cancellable(id: CancelId.timer, cancelInFlight: true)
    }

    private func nukeLocalDatabases() -> Effect<Action> {
        .run { send in
            do {
                try await sdkSynchronizer.nukeLocalDatabases()
                await send(.nukeLocalDatabasesSuccess)
            } catch {
                await send(.nukeLocalDatabasesFailed)
            }
        }
        .cancellable(id: CancelId.timer, cancelInFlight: true)
    }
}
