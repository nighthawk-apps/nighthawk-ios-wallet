//
//  TransferStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import Receive
import NHSendFlow
import TopUp
import Utils
import ZcashLightClientKit

public typealias TransferStore = Store<TransferReducer.State, TransferReducer.Action>
public typealias TransferViewStore = ViewStore<TransferReducer.State, TransferReducer.Action>

public struct TransferReducer: ReducerProtocol {
    let networkType: NetworkType
    
    public struct Destination: ReducerProtocol {
        let networkType: NetworkType
        
        public enum State: Equatable {
            case receive(ReceiveReducer.State)
            case topUp(TopUpReducer.State)
            case send(NHSendFlowReducer.State)
        }
        
        public enum Action: Equatable {
            case receive(ReceiveReducer.Action)
            case topUp(TopUpReducer.Action)
            case send(NHSendFlowReducer.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerProtocolOf<Self> {
            Scope(state: /State.receive, action: /Action.receive) {
                ReceiveReducer()
            }
            
            Scope(state: /State.topUp, action: /Action.topUp) {
                TopUpReducer()
            }
            
            Scope(state: /State.send, action: /Action.send) {
                NHSendFlowReducer(networkType: networkType)
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
            case .receiveMoneyTapped:
                state.destination = .receive(.init())
                return .none
            case .topUpWalletTapped:
                state.destination = .topUp(.init())
                return .none
            case .sendMoneyTapped:
                var sendState = NHSendFlowReducer.State()
                sendState.shieldedBalance = state.shieldedBalance
                state.destination = .send(sendState)
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination(networkType: networkType)
        }
    }
}

// MARK: - Placeholder
extension TransferReducer.State {
    public static var placeholder: Self {
        .init()
    }
}

// MARK: - Store
extension Store<TransferReducer.State, TransferReducer.Action> {
    func destinationStore() -> Store<PresentationState<TransferReducer.Destination.State>, PresentationAction<TransferReducer.Destination.Action>> {
        self.scope(
            state: \.$destination,
            action: { .destination($0) }
        )
    }
}
