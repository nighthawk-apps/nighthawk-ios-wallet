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
        advancedSettingsDelegateReducer()
    }
    
    private func nighthawkSettingsDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .home(.settings(.delegate(delegateAction))))):
                switch delegateAction {
                case let .goTo(screen):
                    return goTo(screen: screen, state: &state)
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .scenePhaseChanged, .splash:
                return .none
            }
        }
    }
    
    private func advancedSettingsDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .advanced(.delegate(delegateAction)))):
                switch delegateAction {
                case .nukeWallet:
                    return nukeWallet()
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .scenePhaseChanged, .splash:
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
            // TODO
            return .none
        case .security:
            state.path.append(.security())
            return .none
        }
    }
    
    private func nukeWallet() -> Effect<Action> {
        guard let wipePublisher = sdkSynchronizer.wipe() else {
            return .send(.nukeWalletFailed)
        }
        
        return .publisher {
            wipePublisher
                .replaceEmpty(with: Void())
                .map { _ in return AppReducer.Action.nukeWalletSuccess }
                .replaceError(with: AppReducer.Action.nukeWalletFailed)
                .receive(on: mainQueue)
        }
        .cancellable(id: CancelId.timer, cancelInFlight: true)
    }
}
