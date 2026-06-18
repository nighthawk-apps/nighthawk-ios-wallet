//
//  Transfer.swift
//  stealth
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import ProcessInfoClient
import Receive
import SendFlow
import Utils

@Reducer
public struct Transfer {
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case receive(Receive)
        case send(SendFlow)
    }
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        @Shared(.walletInfo) var walletInfo = Home.State.WalletInfo()
        
        public var tokenName: String {
            return "DRK"
        }
        
        public init () {}
    }
    
    public enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
        case receiveMoneyTapped
        case sendMoneyTapped
        case daoHubTapped
        case topUpWalletTapped
        
        public enum Delegate: Equatable {
            case openDaoHub
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.processInfo) var processInfo
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case .receiveMoneyTapped:
                state.destination = .receive(
                    .init(
                        uAddress: state.walletInfo.unifiedAddress,
                        showCloseButton: processInfo.isiOSAppOnMac()
                    )
                )
                return .none
            case .sendMoneyTapped:
                var sendState = SendFlow.State(
                    latestFiatPrice: state.walletInfo.latestFiatPrice,
                    showCloseButton: processInfo.isiOSAppOnMac()
                )
                sendState.spendableBalance = state.walletInfo.balance
                sendState.unifiedAddress = state.walletInfo.unifiedAddress
                state.destination = .send(sendState)
                return .none
            case .topUpWalletTapped:
                // TODO: DarkFi: implement peer exchange / swap
                return .none
            case .daoHubTapped:
                return .send(.delegate(.openDaoHub))
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        sendFlowReducer()
    }
    
    public init() {}
}
