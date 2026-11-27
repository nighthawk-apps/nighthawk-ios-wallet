//
//  Wallet.swift
//  stealth
//
//  Created by Matthew watt on 5/5/23.
//

import Addresses
import ComposableArchitecture
import Models
import Pasteboard
import ProcessInfoClient
import SDKSynchronizer
import SwiftUI
import UserPreferencesStorage
import TransactionDetail
import Utils

@Reducer
public struct Wallet {
    @ObservableState
    public struct State: Equatable {
        @Shared(.walletInfo) public var walletInfo = Home.State.WalletInfo()

        public var balanceViewType: BalanceView.ViewType = .hidden

        /// Written by the reducer. Not read from a dependency inside `State`.
        public var isFirstSync = true

        public var isSyncingForFirstTime: Bool {
            walletInfo.synchronizerStatusSnapshot.syncStatus.isSyncing && isFirstSync
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

        public var preferredCurrency: NighthawkSetting.FiatCurrency = .off

        public var latestFiatPrice: Double?
        /// Right-fold selection. Compact width still pushes detail instead.
        public var selectedTransactionID: String?

        public var selectedTransaction: WalletEvent? {
            guard let selectedTransactionID else { return nil }
            return walletInfo.walletEvents[id: selectedTransactionID]
        }

        public var fiatConversion: (NighthawkSetting.FiatCurrency, Double)? {
            if let latestFiatPrice, preferredCurrency != .off {
                (preferredCurrency, latestFiatPrice)
            } else {
                nil
            }
        }

        public var showScanButton = true

        public var tokenName: String {
            return "DRK"
        }

        public static let nativeDrkTokenId = "241vANigf1Cy3ytjM1KHXiVECxgxdK4yApddL8KcLssb"

        /// Non-native custom tokens held in the wallet for portfolio display & tap-to-send.
        public var customTokens: [TokenBalanceInfo] {
            walletInfo.tokenBalances
                .filter { token in
                    let id = token.tokenId.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !id.isEmpty,
                          id != Self.nativeDrkTokenId,
                          id.caseInsensitiveCompare("DRK") != .orderedSame else {
                        return false
                    }
                    if let label = token.displayLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
                       label.caseInsensitiveCompare("DRK") == .orderedSame {
                        return false
                    }
                    return true
                }
                .sorted { $0.balanceAtomic > $1.balanceAtomic }
        }

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case scanPaymentRequestTapped
        case receiveMoneyTapped
        case sendMoneyTapped
        case requestMoneyTapped
        case viewAddressesTapped
        case viewTransactionDetailTapped(WalletEvent)
        case viewTransactionHistoryTapped
        case transactionSelected(WalletEvent)
        case tokenTapped(TokenBalanceInfo)
        case copyTransactionId(String)
        case copyMemo(String)
        case refreshPreferences
        case sendAgainTapped

        public enum Delegate: Equatable {
            case scanPaymentRequest
            case receiveMoney
            case sendMoney
            case sendToken(tokenId: String)
            case requestMoney
            case showAddresses
            case showTransactionHistory(IdentifiedArrayOf<WalletEvent>)
            case showTransactionDetail(WalletEvent)
            case sendAgain(recipient: String, amount: DrkAmount)
        }
    }

    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.processInfo) var processInfo
    @Dependency(\.userStoredPreferences) var userStoredPreferences

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
            case .receiveMoneyTapped:
                return .send(.delegate(.receiveMoney))
            case .sendMoneyTapped:
                return .send(.delegate(.sendMoney))
            case .requestMoneyTapped:
                // Until a dedicated Request invoice screen ships, open Receive QR.
                return .send(.delegate(.requestMoney))
            case .viewAddressesTapped:
                return .send(.delegate(.showAddresses))
            case let .viewTransactionDetailTapped(walletEvent):
                return .send(.delegate(.showTransactionDetail(walletEvent)))
            case .viewTransactionHistoryTapped:
                return .send(.delegate(.showTransactionHistory(state.walletInfo.walletEvents)))
            case let .transactionSelected(event):
                state.selectedTransactionID = event.id
                return .none
            case let .tokenTapped(token):
                return .send(.delegate(.sendToken(tokenId: token.tokenId)))
            case let .copyTransactionId(id):
                pasteboard.setString(id.redacted)
                return .none
            case let .copyMemo(memo):
                pasteboard.setString(memo.redacted)
                return .none
            case .refreshPreferences:
                state.isFirstSync = userStoredPreferences.isFirstSync()
                state.preferredCurrency = userStoredPreferences.fiatCurrency()
                state.showScanButton = !processInfo.isiOSAppOnMac()
                return .none
            case .sendAgainTapped:
                guard let event = state.selectedTransaction,
                      event.transaction.isSending,
                      let recipient = event.transaction.address,
                      !recipient.isEmpty
                else { return .none }
                // The net value of a send is the amount plus the fee.
                let amount = max(abs(event.transaction.drkAmount) - event.transaction.fee, 0)
                return .send(.delegate(.sendAgain(recipient: recipient, amount: amount)))
            }
        }
    }
}
