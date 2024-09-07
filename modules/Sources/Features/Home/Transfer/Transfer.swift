//
//  Transfer.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import ProcessInfoClient
import Receive
import SendFlow
import TopUp
import Utils
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct Transfer {
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case receive(Receive)
        case topUp(TopUp)
        case send(SendFlow)
    }
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        @Shared(.walletInfo) var walletInfo = Home.State.WalletInfo()
        
        public var tokenName: String {
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            return zcashSDKEnvironment.tokenName
        }
        
        public init () {}
    }
    
    public enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case receiveMoneyTapped
        case sendMoneyTapped
        case topUpWalletTapped
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
                sendState.spendableBalance = state.walletInfo.shieldedBalance
                sendState.unifiedAddress = state.walletInfo.unifiedAddress
                state.destination = .send(sendState)
                return .none
            case .topUpWalletTapped:
                state.destination = .topUp(
                    .init(
                        unifiedAddress: state.walletInfo.unifiedAddress,
                        showCloseButton: processInfo.isiOSAppOnMac()
                    )
                )
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        sendFlowReducer()
    }
    
    public init() {}
}

