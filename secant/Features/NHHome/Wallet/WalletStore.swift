//
//  WalletStore.swift
//  secant
//
//  Created by Matthew watt on 5/5/23.
//

import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit

struct WalletReducer: ReducerProtocol {
    struct State: Equatable {
        enum Destination: Equatable {
            case showWalletEvent(WalletEvent)
            case transactionHistory
        }
        
        var destination: Destination?
        
        var latestMinedHeight: BlockHeight?
        var requiredTransactionConfirmations = 0
        var synchronizerStatusSnapshot: SyncStatusSnapshot
        var shieldedBalance: Balance
        var transparentBalance: Balance
        @BindingState var balanceViewType: BalanceView.ViewType = .hidden
        var walletEvents = IdentifiedArrayOf<WalletEvent>.placeholder
        var selectedWalletEvent: WalletEvent?
        
        var isSyncing: Bool {
            if case .syncing = synchronizerStatusSnapshot.syncStatus {
                return true
            }
            return false
        }
        
        var isSyncingFailed: Bool {
            if case .error = synchronizerStatusSnapshot.syncStatus {
                return true
            }
            return false
        }
        
        var isUpToDate: Bool {
            if case .synced = synchronizerStatusSnapshot.syncStatus {
                return true
            }
            return false
        }
        
        var totalBalance: Zatoshi {
            shieldedBalance.data.total + transparentBalance.data.total
        }
        
        var transactionHistoryState: TransactionHistoryReducer.State
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case updateDestination(WalletReducer.State.Destination?)
        case transactionHistory(TransactionHistoryReducer.Action)
        case viewTransactionHistory
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Scope(state: \.transactionHistory, action: /Action.transactionHistory) {
            TransactionHistoryReducer()
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
            case .binding, .transactionHistory:
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
}

// MARK: - Placeholder
extension WalletReducer.State {
    static var placeholder: Self {
        .init(
            synchronizerStatusSnapshot: .default,
            shieldedBalance: .zero,
            transparentBalance: .zero,
            transactionHistoryState: .placeholder
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
