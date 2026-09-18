//
//  Wallet.swift
//  stealth
//

import Addresses
import ComposableArchitecture
import Models
import ProcessInfoClient
import SDKSynchronizer
import SwiftUI
import TransactionDetail
import Utils

@Reducer
public struct Wallet {
    @ObservableState
    public struct State: Equatable {
        @Shared(.walletInfo) public var walletInfo = Home.State.WalletInfo()

        public var balanceViewType: BalanceView.ViewType = .hidden

        /// Custom tokens from `listTokenBalances`. DRK is synthesized in `portfolioRows`.
        public var tokenBalances: [TokenBalanceInfo] = []

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
            return "DRK"
        }

        /// DRK first (native snapshot), then every other listed token.
        public var portfolioRows: [TokenBalanceInfo] {
            TokenBalanceInfo.portfolioRows(
                nativeAtomic: walletInfo.totalBalance,
                tokenBalances: tokenBalances
            )
        }

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case onAppear
        case scanPaymentRequestTapped
        case sendTokenTapped(TokenBalanceInfo)
        case tokenBalancesLoaded([TokenBalanceInfo])
        case viewAddressesTapped
        case viewTransactionDetailTapped(WalletEvent)
        case viewTransactionHistoryTapped

        public enum Delegate: Equatable {
            case scanPaymentRequest
            case showAddresses
            case showTransactionHistory(IdentifiedArrayOf<WalletEvent>)
            case showTransactionDetail(WalletEvent)
            /// Token id to preselect in Send. `"DRK"` (or empty) means native.
            case sendToken(String)
        }
    }

    @Dependency(\.sdkSynchronizer) var sdkSynchronizer

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .delegate:
                return .none
            case .onAppear:
                return .run { send in
                    let tokens = (try? await sdkSynchronizer.listTokenBalances()) ?? []
                    await send(.tokenBalancesLoaded(tokens))
                }
            case .scanPaymentRequestTapped:
                return .send(.delegate(.scanPaymentRequest))
            case let .sendTokenTapped(token):
                let id = token.isNative ? "DRK" : token.tokenId
                return .send(.delegate(.sendToken(id)))
            case let .tokenBalancesLoaded(tokens):
                state.tokenBalances = tokens
                return .none
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
