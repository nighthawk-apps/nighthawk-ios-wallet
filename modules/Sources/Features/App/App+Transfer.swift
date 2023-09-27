//
//  App+Transfer.swift
//
//
//  Created by Matthew Watt on 9/27/23.
//

import ComposableArchitecture

extension AppReducer {
    @ReducerBuilder<State, Action>
    func transferReducer() -> some ReducerOf<Self> {
        sendFlowDelegateReducer()
    }
    
    private func sendFlowDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .home(.transfer(.destination(.presented(.send(.path(.element(id: _, action: .success(.delegate(delegateAction))))))))))):
                switch delegateAction {
                case .goHome:
                    return .none
                case let .showTransactionDetails(walletEvent):
                    state.path.append(.transactionDetail(.init(walletEvent: walletEvent, networkType: zcashNetwork.networkType)))
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .scenePhaseChanged, .splash:
                return .none
            }
        }
    }
}
