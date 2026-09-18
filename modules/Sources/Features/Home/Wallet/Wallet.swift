//
//  Wallet.swift
//  stealth
//

import Addresses
import ComposableArchitecture
import Models
import ProcessInfoClient
import Receive
import SDKSynchronizer
import SendFlow
import SwiftUI
import TransactionDetail
import Utils

@Reducer
public struct Wallet {
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case receive(Receive)
        case send(SendFlow)
        case request(RequestMoney)
    }

    @ObservableState
    public struct State: Equatable {
        @Shared(.walletInfo) public var walletInfo = Home.State.WalletInfo()
        @Presents public var destination: Destination.State?

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
        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case receiveMoneyTapped
        case requestMoneyTapped
        case scanPaymentRequestTapped
        case sendMoneyTapped
        case sendTokenTapped(TokenBalanceInfo)
        case tokenBalancesLoaded([TokenBalanceInfo])
        case viewAddressesTapped
        case viewTransactionDetailTapped(WalletEvent)
        case viewTransactionHistoryTapped

        public enum Delegate: Equatable {
            case showAddresses
            case showTransactionHistory(IdentifiedArrayOf<WalletEvent>)
            case showTransactionDetail(WalletEvent)
        }
    }

    @Dependency(\.processInfo) var processInfo
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .delegate:
                return .none
            case .destination:
                return .none
            case .onAppear:
                return .run { send in
                    let tokens = (try? await sdkSynchronizer.listTokenBalances()) ?? []
                    await send(.tokenBalancesLoaded(tokens))
                }
            case .receiveMoneyTapped:
                state.destination = .receive(
                    .init(
                        uAddress: state.walletInfo.unifiedAddress,
                        showCloseButton: processInfo.isiOSAppOnMac()
                    )
                )
                return .none
            case .requestMoneyTapped:
                state.destination = .request(
                    .init(
                        address: state.walletInfo.unifiedAddress?.stringEncoded ?? "",
                        showCloseButton: processInfo.isiOSAppOnMac()
                    )
                )
                return .none
            case .scanPaymentRequestTapped:
                presentSend(
                    state: &state,
                    path: StackState([.scan(.init(backButtonType: .close))])
                )
                return .none
            case .sendMoneyTapped:
                presentSend(state: &state)
                return .none
            case let .sendTokenTapped(token):
                presentSend(
                    state: &state,
                    preselectedTokenId: token.isNative ? nil : token.tokenId
                )
                return .none
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
        .ifLet(\.$destination, action: \.destination)

        sendFlowReducer()
    }

    private func presentSend(
        state: inout State,
        path: StackState<SendFlow.Path.State> = .init(),
        preselectedTokenId: String? = nil
    ) {
        var sendState = SendFlow.State(
            path: path,
            latestFiatPrice: state.walletInfo.latestFiatPrice,
            showCloseButton: processInfo.isiOSAppOnMac(),
            preselectedTokenId: preselectedTokenId
        )
        sendState.spendableBalance = state.walletInfo.balance
        sendState.unifiedAddress = state.walletInfo.unifiedAddress
        state.destination = .send(sendState)
    }
}
