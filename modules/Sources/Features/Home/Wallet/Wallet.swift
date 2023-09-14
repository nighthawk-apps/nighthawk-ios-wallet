//
//  Wallet.swift
//  secant
//
//  Created by Matthew watt on 5/5/23.
//

import Addresses
import ComposableArchitecture
import Models
import SwiftUI
import TransactionDetail
import Utils
import ZcashLightClientKit

public struct Wallet: ReducerProtocol {
    public struct State: Equatable {
        public var autoShieldingThreshold: Zatoshi = Zatoshi(1_000_000)
        public var latestMinedHeight: BlockHeight?
        public var requiredTransactionConfirmations = 0
        public var synchronizerStatusSnapshot: SyncStatusSnapshot = .default
        public var shieldedBalance: Balance = .zero
        public var transparentBalance: Balance = .zero
        @BindingState public var balanceViewType: BalanceView.ViewType = .hidden
        public var walletEvents: IdentifiedArrayOf<WalletEvent> = []
        public var isSyncingFailed: Bool {
            if case .error = synchronizerStatusSnapshot.syncStatus {
                return true
            }
            return false
        }
        
        public var totalBalance: Zatoshi {
            shieldedBalance.data.total + transparentBalance.data.total
        }
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case viewTransactionHistoryTapped
        case viewAddressesTapped
        
        public enum Delegate: Equatable {
            case showTransactionHistory
            case showAddresses
        }
    }
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .delegate:
                return .none
            case .viewAddressesTapped:
                return .run { send in await send(.delegate(.showAddresses)) }
            case .viewTransactionHistoryTapped:
                return .run { send in await send(.delegate(.showTransactionHistory)) }
            }
        }
    }
}
