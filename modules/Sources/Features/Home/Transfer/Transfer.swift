//
//  Transfer.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import Receive
import SendFlow
import TopUp
import Utils
import ZcashLightClientKit

public struct Transfer: Reducer {
    let networkType: NetworkType
    
    public struct Destination: Reducer {
        let networkType: NetworkType
        
        public enum State: Equatable {
            case receive(Receive.State)
            case topUp(TopUp.State)
            case send(SendFlow.State)
        }
        
        public enum Action: Equatable {
            case receive(Receive.Action)
            case topUp(TopUp.Action)
            case send(SendFlow.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.receive, action: /Action.receive) {
                Receive()
            }
            
            Scope(state: /State.topUp, action: /Action.topUp) {
                TopUp()
            }
            
            Scope(state: /State.send, action: /Action.send) {
                SendFlow(networkType: networkType)
            }
        }
    }
    
    public struct State: Equatable {
        @PresentationState public var destination: Destination.State?
        public var shieldedBalance: Balance = .zero
        public var unifiedAddress: UnifiedAddress?
        
        public init () {}
    }
    
    public enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case receiveMoneyTapped
        case sendMoneyTapped
        case topUpWalletTapped
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case .receiveMoneyTapped:
                state.destination = .receive(.init(uAddress: state.unifiedAddress))
                return .none
            case .sendMoneyTapped:
                var sendState = SendFlow.State()
                sendState.shieldedBalance = state.shieldedBalance
                sendState.unifiedAddress = state.unifiedAddress
                state.destination = .send(sendState)
                return .none
            case .topUpWalletTapped:
                state.destination = .topUp(.init(unifiedAddress: state.unifiedAddress))
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination(networkType: networkType)
        }
        
        sendFlowReducer()
    }
}

