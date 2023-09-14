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

public struct Transfer: ReducerProtocol {
    let networkType: NetworkType
    
    public struct Destination: ReducerProtocol {
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
        
        public var body: some ReducerProtocolOf<Self> {
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
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case .receiveMoneyTapped:
                state.destination = .receive(.init())
                return .none
            case .sendMoneyTapped:
                var sendState = SendFlow.State()
                sendState.shieldedBalance = state.shieldedBalance
                state.destination = .send(sendState)
                return .none
            case .topUpWalletTapped:
                state.destination = .topUp(.init())
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination(networkType: networkType)
        }
        
        sendFailedDelegateReducer()
    }
}

// MARK: - Send failed delegate
extension Transfer {
    func sendFailedDelegateReducer() -> Reduce<Transfer.State, Transfer.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.send(.path(.element(id: _, action: .failed(.delegate(delegateAction))))))):
                switch delegateAction {
                case .cancelTransaction:
                    state.destination = nil
                }
                return .none
            case .destination,
                 .receiveMoneyTapped,
                 .sendMoneyTapped,
                 .topUpWalletTapped:
                return .none
            }
        }
    }
}
