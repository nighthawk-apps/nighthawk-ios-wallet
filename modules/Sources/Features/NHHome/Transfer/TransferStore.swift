//
//  TransferStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import Receive
import TopUp

public typealias TransferStore = Store<TransferReducer.State, TransferReducer.Action>
public typealias TransferViewStore = ViewStore<TransferReducer.State, TransferReducer.Action>

public struct TransferReducer: ReducerProtocol {
    public struct Destination: ReducerProtocol {
        public enum State: Equatable {
            case receive(ReceiveReducer.State)
            case topUp(TopUpReducer.State)
        }
        
        public enum Action: Equatable {
            case receive(ReceiveReducer.Action)
            case topUp(TopUpReducer.Action)
        }
        
        public var body: some ReducerProtocolOf<Self> {
            Scope(state: /State.receive, action: /Action.receive) {
                ReceiveReducer()
            }
            
            Scope(state: /State.topUp, action: /Action.topUp) {
                TopUpReducer()
            }
        }
    }
    
    public struct State: Equatable {
        @PresentationState public var destination: Destination.State?
    }
    
    public enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case receiveMoneyTapped
        case topUpWalletTapped
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
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
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
