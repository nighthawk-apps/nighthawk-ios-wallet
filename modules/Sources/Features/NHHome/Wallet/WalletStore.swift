//
//  WalletStore.swift
//  secant
//
//  Created by Matthew watt on 5/5/23.
//

import ComposableArchitecture
import Models
import SwiftUI
import NHTransactionDetail
import Utils
import ZcashLightClientKit

public typealias WalletStore = Store<WalletReducer.State, WalletReducer.Action>

public struct WalletReducer: ReducerProtocol {
    public struct State: Equatable {
        public enum Destination: Equatable {
            case showWalletEvent(WalletEvent)
            case transactionHistory
        }
        
        public var destination: Destination?
        
        public var autoShieldingThreshold: Zatoshi
        public var latestMinedHeight: BlockHeight?
        public var requiredTransactionConfirmations = 0
        public var synchronizerStatusSnapshot: SyncStatusSnapshot
        public var shieldedBalance: Balance
        public var transparentBalance: Balance
        @BindingState public var balanceViewType: BalanceView.ViewType = .hidden
        public var walletEvents = IdentifiedArrayOf<WalletEvent>.placeholder
        public var selectedWalletEvent: WalletEvent?
        
        public var isSyncingFailed: Bool {
            if case .error = synchronizerStatusSnapshot.syncStatus {
                return true
            }
            return false
        }
        
        public var totalBalance: Zatoshi {
            shieldedBalance.data.total + transparentBalance.data.total
        }
        
        public var transactionHistoryState: TransactionHistoryReducer.State
        public var transactionDetailState: NHTransactionDetailReducer.State
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case updateDestination(WalletReducer.State.Destination?)
        case transactionHistory(TransactionHistoryReducer.Action)
        case transactionDetail(NHTransactionDetailReducer.Action)
        case viewTransactionHistory
        case viewAddressesTapped
    }
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Scope(state: \.transactionHistory, action: /Action.transactionHistory) {
            TransactionHistoryReducer()
        }
        
        Scope(state: \.transactionDetail, action: /Action.transactionDetail) {
            NHTransactionDetailReducer()
        }
        
        Reduce { state, action in
            switch action {
            case .updateDestination(.showWalletEvent(let walletEvent)):
                state.selectedWalletEvent = walletEvent
                state.destination = .showWalletEvent(walletEvent)
                return .none
            case let .updateDestination(destination):
                state.destination = destination
                if destination == nil {
                    state.selectedWalletEvent = nil
                }
                return .none
            case .viewTransactionHistory:
                return .task { .updateDestination(.transactionHistory) }
            case .binding, .transactionHistory, .transactionDetail, .viewAddressesTapped:
                return .none
            }
        }
    }
}

// MARK: - Shared state synchronization
extension WalletReducer.State {
    var transactionHistory: TransactionHistoryReducer.State {
        get {
            var state = transactionHistoryState
            state.walletEvents = walletEvents
            return state
        }
        
        set {
            self.transactionHistoryState = newValue
            self.walletEvents = newValue.walletEvents
        }
    }
    
    var transactionDetail: NHTransactionDetailReducer.State {
        get {
            var state = transactionDetailState
            state.latestMinedHeight = latestMinedHeight
            state.requiredTransactionConfirmations = requiredTransactionConfirmations
            if let event = selectedWalletEvent, case let .transaction(transaction) = event.state {
                state.transaction = transaction
            }
            return state
        }
        
        set {
            self.transactionDetailState = newValue
        }
    }
}

// MARK: - Placeholder
extension WalletReducer.State {
    static var placeholder: Self {
        .init(
            autoShieldingThreshold: Zatoshi(1_000_000),
            synchronizerStatusSnapshot: .default,
            shieldedBalance: .zero,
            transparentBalance: .zero,
            transactionHistoryState: .placeholder,
            transactionDetailState: .placeholder
        )
    }
}

// MARK: - Store
extension Store<WalletReducer.State, WalletReducer.Action> {
    func transactionHistoryStore() -> Store<TransactionHistoryReducer.State, TransactionHistoryReducer.Action> {
        self.scope(
            state: \.transactionHistory,
            action: Action.transactionHistory
        )
    }
    
    func transactionDetailStore() -> NHTransactionDetailStore {
        self.scope(
            state: \.transactionDetail,
            action: Action.transactionDetail
        )
    }
}

// MARK: - ViewStore
extension ViewStore<WalletReducer.State, WalletReducer.Action> {
    func bindingForDestination(_ destination: WalletReducer.State.Destination) -> Binding<Bool> {
        self.binding(
            get: { $0.destination == destination },
            send: { isActive in
                return .updateDestination(isActive ? destination : nil)
            }
        )
    }
    
    func bindingForSelectedWalletEvent(_ walletEvent: WalletEvent?) -> Binding<Bool> {
        self.binding(
            get: {
                guard let walletEvent else {
                    return false
                }
                
                return $0.destination.map(/WalletReducer.State.Destination.showWalletEvent) == walletEvent
            },
            send: { isActive in
                guard let walletEvent else {
                    return WalletReducer.Action.updateDestination(nil)
                }
                
                return WalletReducer.Action.updateDestination(
                    isActive ? WalletReducer.State.Destination.showWalletEvent(walletEvent) : nil
                )
            }
        )
    }
}