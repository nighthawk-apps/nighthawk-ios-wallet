//
//  WalletStore.swift
//  secant
//
//  Created by Matthew watt on 5/5/23.
//

import ComposableArchitecture
import ZcashLightClientKit

struct WalletReducer: ReducerProtocol {
    struct State: Equatable {
        enum Destination: Equatable {
            case showWalletEvent(WalletEvent)
        }
        
        var destination: Destination?
        
        var latestMinedHeight: BlockHeight?
        var requiredTransactionConfirmations = 0
        var synchronizerStatusSnapshot: SyncStatusSnapshot
        var shieldedBalance: Balance
        var transparentBalance: Balance
        @BindingState var balanceViewType: BalanceView.ViewType = .hidden
        var walletEvents = IdentifiedArrayOf<WalletEvent>.placeholder
        
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
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case updateDestination(WalletReducer.State.Destination?)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case let .updateDestination(destination):
                state.destination = destination
                return .none
            case .binding:
                return .none
            }
        }
    }
}

// MARK: - Placeholder
extension WalletReducer.State {
    static var placeholder: Self {
        .init(
            synchronizerStatusSnapshot: .default,
            shieldedBalance: .zero,
            transparentBalance: .zero
        )
    }
}
