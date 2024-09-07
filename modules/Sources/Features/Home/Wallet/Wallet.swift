//
//  Wallet.swift
//  secant
//
//  Created by Matthew watt on 5/5/23.
//

import Addresses
import ComposableArchitecture
import Models
import ProcessInfoClient
import SwiftUI
import TransactionDetail
import Utils
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct Wallet {
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.walletInfo) public var walletInfo = Home.State.WalletInfo()
        
        public var balanceViewType: BalanceView.ViewType = .hidden
        
        public var isSyncingForFirstTime: Bool {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return walletInfo.synchronizerStatusSnapshot.syncStatus.isSyncing && userStoredPreferences.isFirstSync()
        }
        
        public var isSyncingFailed: Bool {
            if case .error = walletInfo.synchronizerStatusSnapshot.syncStatus {
                return true
            }
            return false
        }
        
        public var isSyncingStopped: Bool {
            if case .stopped = walletInfo.synchronizerStatusSnapshot.syncStatus {
                return true
            }
            return false
        }
        
        public var preferredCurrency: NighthawkSetting.FiatCurrency {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return userStoredPreferences.fiatCurrency()
        }
        
        public var latestFiatPrice: Double?
        
        public var fiatConversion: (NighthawkSetting.FiatCurrency, Double)? {
            if let latestFiatPrice, preferredCurrency != .off {
                (preferredCurrency, latestFiatPrice)
            } else {
                nil
            }
        }
        
        public var showScanButton: Bool {
            @Dependency(\.processInfo) var processInfo
            return !processInfo.isiOSAppOnMac()
        }
        
        public var tokenName: String {
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            return zcashSDKEnvironment.tokenName
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
            case showTransactionHistory(IdentifiedArrayOf<WalletEvent>)
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
                return .send(.delegate(.showTransactionHistory(state.walletInfo.walletEvents)))
            }
        }
    }
}
