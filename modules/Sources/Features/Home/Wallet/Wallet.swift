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

public struct Wallet: Reducer {
    public struct State: Equatable {
        public var autoShieldingThreshold: Zatoshi = Zatoshi(1_000_000)
        public var latestMinedHeight: BlockHeight?
        public var requiredTransactionConfirmations = 0
        public var synchronizerState: SynchronizerState = .zero
        public var synchronizerStatusSnapshot: SyncStatusSnapshot = .default
        public var shieldedBalance: Balance = .zero
        public var transparentBalance: Balance = .zero
        public var expectingZatoshi: Zatoshi = .zero
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
        case scanPaymentRequestTapped
        case shieldNowTapped
        case viewAddressesTapped
        case viewTransactionDetailTapped(WalletEvent)
        case viewTransactionHistoryTapped
        
        public enum Delegate: Equatable {
            case scanPaymentRequest
            case shieldFunds
            case showAddresses
            case showTransactionHistory
            case showTransactionDetail(WalletEvent)
        }
    }
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .delegate:
                return .none
            case .scanPaymentRequestTapped:
                return .send(.delegate(.scanPaymentRequest))
            case .shieldNowTapped:
                return .send(.delegate(.shieldFunds))
            case .viewAddressesTapped:
                return .send(.delegate(.showAddresses))
            case let .viewTransactionDetailTapped(walletEvent):
                return .send(.delegate(.showTransactionDetail(walletEvent)))
            case .viewTransactionHistoryTapped:
                return .send(.delegate(.showTransactionHistory))
            }
        }
    }
}
