//
//  Home.swift
//  stealth
//
//  Created by Matthew Watt on 5/5/23.
//

import Addresses
import ComposableArchitecture
import DataManager
import DiskSpaceChecker
import FiatPriceClient
import FileManager
import Foundation
import Models
import ProcessInfoClient
import SDKSynchronizer
import UIKit
import UserPreferencesStorage
import Utils

@Reducer
public struct Home {
    enum CancelId { case timer }

    @ObservableState
    public struct State: Equatable {
        public enum Tab: Equatable, Hashable {
            case chat
            case wallet
            case dex
            case daoHub
            case settings
        }

        public enum Toast {
            case expectingFunds
        }

        public struct WalletInfo: Equatable {
            public var requiredTransactionConfirmations = 0
            public var latestMinedHeight: BlockHeight?
            public var latestFiatPrice: Double?
            public var balance: DrkAmount = .init()
            public var totalBalance: DrkAmount = .init()
            public var expectingAmount: DrkAmount = .zero
            public var synchronizerState: SynchronizerState = .zero
            public var synchronizerStatusSnapshot: SyncStatusSnapshot = .default
            public var unifiedAddress: UnifiedAddress?
            public var walletEvents: IdentifiedArrayOf<WalletEvent>

            public init(
                unifiedAddress: UnifiedAddress? = nil,
                walletEvents: IdentifiedArrayOf<WalletEvent> = IdentifiedArrayOf<WalletEvent>()
            ) {
                self.unifiedAddress = unifiedAddress
                self.walletEvents = walletEvents
            }
        }

        @Presents public var alert: AlertState<Action.Alert>?
        @Presents public var destination: Destination.State?
        public var selectedTab = Tab.chat
        public var toast: Toast?

        public var synchronizerFailedToStart = false
        public var synchronizerFailed: Bool {
            synchronizerFailedToStart || walletInfo.synchronizerStatusSnapshot.isSyncFailed
        }

        public var preferredCurrency: NighthawkSetting.FiatCurrency = .off

        public var tokenName: String {
            return "DRK"
        }

        // Shared state
        @Shared public var walletInfo: WalletInfo

        // Tab states
        public var wallet: Wallet.State = .init()
        public var transfer: Transfer.State = .init()
        public var chat: Chat.State = .init()
        public var daoHub: DaoHub.State = .init()
        public var settings: NighthawkSettings.State = .init()

        public init(unifiedAddress: UnifiedAddress?) {
            self._walletInfo = Shared(wrappedValue: WalletInfo(), .walletInfo)
            let events = loadCachedEvents()
            let walletInfo = WalletInfo(unifiedAddress: unifiedAddress, walletEvents: events)
            self.walletInfo = walletInfo
        }

        func loadCachedEvents() -> IdentifiedArrayOf<WalletEvent> {
            if let latestEventsCache = URL.latestEventsCache(for: "testnet"),
               let cachedData = try? Data(contentsOf: latestEventsCache),
               let events = try? JSONDecoder().decode([WalletEvent].self, from: cachedData) {
                return IdentifiedArray(uniqueElements: events)
            }

            return []
        }
    }

    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case cancelSynchronizerUpdates
        case cantStartSync(DarkFiError)
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case fetchLatestFiatPrice
        case latestFiatResponse(Double?)
        case listenForSynchronizerUpdates
        case onAppear
        case rescanDone(DarkFiError? = nil)
        case chat(Chat.Action)
        case daoHub(DaoHub.Action)
        case settings(NighthawkSettings.Action)
        case synchronizerStateChanged(SynchronizerState)
        case tabSelected(State.Tab)
        case transfer(Transfer.Action)
        case updateWalletEvents([WalletEvent])
        case unifiedAddressLoaded(UnifiedAddress?)
        case wallet(Wallet.Action)

        public enum Alert: Equatable {}

        public enum Delegate: Equatable {
            case setLatestFiatPrice(Double?)
            case unifiedAddressResponse(UnifiedAddress?)
            case openDaoHub
            case openChatSettings
        }
    }

    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case addresses(Addresses)
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.dataManager) var dataManager
    @Dependency(\.diskSpaceChecker) var diskSpaceChecker
    @Dependency(\.fiatPriceClient) var fiatPriceClient
    @Dependency(\.fileManager) var fileManager
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.processInfo) var processInfo
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.wallet, action: \.wallet) {
            Wallet()
        }

        Scope(state: \.transfer, action: \.transfer) {
            Transfer()
        }

        Scope(state: \.chat, action: \.chat) {
            Chat()
        }

        Scope(state: \.daoHub, action: \.daoHub) {
            DaoHub()
        }

        Scope(state: \.settings, action: \.settings) {
            NighthawkSettings()
        }

        Reduce { state, action in
            switch action {
            case .cancelSynchronizerUpdates:
                return .cancel(id: CancelId.timer)
            case let .cantStartSync(error):
                state.alert = .cantStartSync(error)
                return .none
            case .fetchLatestFiatPrice:
                state.preferredCurrency = userStoredPreferences.fiatCurrency()
                guard state.preferredCurrency != .off else { return .none }
                return .run { [preferredCurrency = state.preferredCurrency] send in
                    let price = try? await fiatPriceClient.getDrkPrice(preferredCurrency)
                    await send(.latestFiatResponse(price))
                    await send(.delegate(.setLatestFiatPrice(price)))
                }
            case let .latestFiatResponse(price):
                state.walletInfo.latestFiatPrice = price
                return .none
            case .onAppear:
                state.preferredCurrency = userStoredPreferences.fiatCurrency()
                state.wallet.isFirstSync = userStoredPreferences.isFirstSync()
                state.wallet.preferredCurrency = state.preferredCurrency
                state.wallet.showScanButton = !processInfo.isiOSAppOnMac()
                state.walletInfo.requiredTransactionConfirmations = 11
                UIApplication.shared.isIdleTimerDisabled = userStoredPreferences.screenMode() == .keepOn
                return .concatenate(
                    .send(.fetchLatestFiatPrice),
                    .send(.listenForSynchronizerUpdates),
                    // Eagerly fetch address — it's available before sync completes
                    .run { send in
                        let ua = try? await sdkSynchronizer.getAddress()
                        await send(.unifiedAddressLoaded(ua))
                    }
                )
            case let .rescanDone(error):
                userStoredPreferences.setIsFirstSync(true)
                if let error {
                    state.alert = .rescanFailed(error.toDarkFiError())
                    return .none
                } else {
                    if let eventsCache = URL.latestEventsCache(for: "testnet") {
                        try? fileManager.removeItem(eventsCache)
                    }
                    return .run { send in
                        do {
                            try await sdkSynchronizer.start(false)
                            await send(.cancelSynchronizerUpdates)
                            await send(.listenForSynchronizerUpdates)
                        } catch {
                            await send(.cantStartSync(error.toDarkFiError()))
                        }
                    }
                }
            case .listenForSynchronizerUpdates:
                if diskSpaceChecker.hasEnoughFreeSpaceForSync() {
                    return .publisher {
                        sdkSynchronizer.stateStream()
                            .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                            .map(Home.Action.synchronizerStateChanged)
                    }
                    .cancellable(id: CancelId.timer, cancelInFlight: true)
                } else {
                    state.alert = .notEnoughFreeDiskSpace()
                    return .none
                }
            case .synchronizerStateChanged(let latestState):
                let snapshot = SyncStatusSnapshot.snapshotFor(state: latestState)
                guard snapshot != state.walletInfo.synchronizerStatusSnapshot else {
                    return .none
                }
                state.walletInfo.synchronizerState = latestState
                state.walletInfo.synchronizerStatusSnapshot = snapshot
                let balance = latestState.confirmedBalance
                state.walletInfo.balance = balance
                state.walletInfo.totalBalance = balance

                if latestState.syncStatus == .upToDate {
                    userStoredPreferences.setIsFirstSync(false)
                    state.walletInfo.latestMinedHeight = sdkSynchronizer.latestState().latestBlockHeight

                    // Detect if there are any expected funds
                    let availableBalance = state.walletInfo.balance
                    if state.walletInfo.totalBalance != availableBalance && (state.walletInfo.totalBalance - availableBalance) != state.walletInfo.expectingAmount {
                        state.walletInfo.expectingAmount = state.walletInfo.totalBalance - availableBalance
                        state.toast = .expectingFunds
                    }
                }

                // Address must land in walletInfo before history will load.
                // Refresh it whenever it is missing or the chain is up to date.
                if state.walletInfo.unifiedAddress == nil || latestState.syncStatus == .upToDate {
                    let loadHistory = latestState.syncStatus == .upToDate
                    return .run { send in
                        let ua = try? await sdkSynchronizer.getAddress()
                        await send(.unifiedAddressLoaded(ua))
                        guard loadHistory else { return }
                        if let overviews = try? await sdkSynchronizer.getAllTransactions() {
                            let events = overviews.map { overview in
                                WalletEvent(transaction: TransactionState(from: overview))
                            }
                            await send(.updateWalletEvents(events))
                        }
                    }
                }

                return .none
            case let .unifiedAddressLoaded(unifiedAddress):
                if let unifiedAddress {
                    state.walletInfo.unifiedAddress = unifiedAddress
                }
                return .send(.delegate(.unifiedAddressResponse(unifiedAddress)))
            case let .tabSelected(tab):
                state.selectedTab = tab
                if tab == .daoHub {
                    return .send(.daoHub(.onAppear))
                }
                return .none
            case let .updateWalletEvents(walletEvents):
                let chainTip = sdkSynchronizer.latestState().latestBlockHeight + 1

                // Cache two latest events
                let events = IdentifiedArrayOf(uniqueElements: walletEvents.sortedEvents(with: chainTip))
                if let cache = URL.latestEventsCache(for: "testnet") {
                    let latest = IdentifiedArray(events.prefix(2)).elements
                    if let data = try? JSONEncoder().encode(latest) {
                        try? dataManager.save(data, cache)
                    }
                }

                state.walletInfo.walletEvents = IdentifiedArrayOf(uniqueElements: events)
                return .none
            case .alert, .binding, .chat, .delegate, .destination, .daoHub, .settings, .transfer, .wallet:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)

        transferReducer()
        walletReducer()
        chatReducer()
        nighthawkSettingsReducer()
    }

    public init() {}
}

// MARK: - Shared state
extension SharedKey where Self == InMemoryKey<Home.State.WalletInfo> {
    public static var walletInfo: Self {
        inMemory(String(describing: Home.State.WalletInfo.self))
    }
}
