//
//  Home+Chat.swift
//
//  Forwards chat chrome actions (settings / request) out of the Chat tab.
//

import ComposableArchitecture
import Receive

extension Home {
    @ReducerBuilder<State, Action>
    func chatReducer() -> some ReducerOf<Self> {
        chatDelegateReducer()
    }

    private func chatDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .chat(.delegate(delegateAction)):
                switch delegateAction {
                case .openChatSettings:
                    return .send(.delegate(.openChatSettings))
                case .requestMoney:
                    state.transfer.destination = .request(
                        .init(
                            address: state.walletInfo.unifiedAddress?.stringEncoded ?? "",
                            showCloseButton: processInfo.isiOSAppOnMac()
                        )
                    )
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
                 .daoHub,
                 .latestFiatResponse,
                 .listenForSynchronizerUpdates,
                 .onAppear,
                 .rescanDone,
                 .settings,
                 .synchronizerStateChanged,
                 .tabSelected,
                 .transfer,
                 .updateWalletEvents,
                 .unifiedAddressLoaded,
                 .wallet:
                return .none
            }
        }
    }
}
