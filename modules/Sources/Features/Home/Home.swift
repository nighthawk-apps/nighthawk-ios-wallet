//
//  Home.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import Addresses
import Autoshield
import ComposableArchitecture
import DataManager
import DiskSpaceChecker
import FiatPriceClient
import FileManager
import Foundation
import Models
import ProcessInfoClient
import UserPreferencesStorage
import SDKSynchronizer
import UIKit
import Utils
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct Home {    
    enum CancelId { case timer }
    
    @ObservableState
    public struct State: Equatable {
        public enum Tab: Equatable, Hashable {
            case wallet
            case transfer
            case settings
        }
        
        public enum Toast {
            case expectingFunds
        }
        
        @Presents public var alert: AlertState<Action.Alert>?
        @Presents public var destination: Destination.State?
        public var selectedTab = Tab.wallet
        public var toast: Toast?
        
        public var synchronizerFailedToStart = false
        public var synchronizerFailed: Bool {
            synchronizerFailedToStart || synchronizerStatusSnapshot.isSyncFailed
        }
        
        public var preferredCurrency: NighthawkSetting.FiatCurrency {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return userStoredPreferences.fiatCurrency()
        }
        public var latestFiatPrice: Double?
        
        public var tokenName: String {
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            return zcashSDKEnvironment.tokenName
        }
        
        // Shared state
        public var requiredTransactionConfirmations = 0
        public var latestMinedHeight: BlockHeight?
        public var shieldedBalance: Zatoshi = .init()
        public var transparentBalance: Zatoshi = .init()
        public var totalBalance: Zatoshi = .init()
        public var expectingZatoshi: Zatoshi = .zero
        public var synchronizerState: SynchronizerState = .zero
        public var synchronizerStatusSnapshot: SyncStatusSnapshot = .default
        public var unifiedAddress: UnifiedAddress?
        public var walletEvents = IdentifiedArrayOf<WalletEvent>()
        
        // Tab states
        public var walletState: Wallet.State = .init()
        public var transferState: Transfer.State = .init()
        public var settings: NighthawkSettings.State = .init()
        
        public init(unifiedAddress: UnifiedAddress?) {
            self.unifiedAddress = unifiedAddress
            self.walletEvents = loadCachedEvents()
        }
        
        func loadCachedEvents() -> IdentifiedArrayOf<WalletEvent> {
            @Dependency(\.dataManager) var dataManager
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            if let latestEventsCache = URL.latestEventsCache(for: zcashSDKEnvironment.network.networkType),
                let cachedData = try? dataManager.load(latestEventsCache),
                let events = try? JSONDecoder().decode([WalletEvent].self, from: cachedData) {
                return IdentifiedArray(uniqueElements: events)
            }
            
            return []
        }
        
        // MARK: - Shared state synchronization
        var wallet: Wallet.State {
            get {
                var state = walletState
                state.synchronizerState = synchronizerState
                state.synchronizerStatusSnapshot = synchronizerStatusSnapshot
                state.shieldedBalance = shieldedBalance
                state.transparentBalance = transparentBalance
                state.totalBalance = totalBalance
                state.latestFiatPrice = latestFiatPrice
                state.latestMinedHeight = latestMinedHeight
                state.expectingZatoshi = expectingZatoshi
                state.requiredTransactionConfirmations = requiredTransactionConfirmations
                state.walletEvents = walletEvents
                return state
            }
            
            set {
                self.walletState = newValue
                self.synchronizerState = newValue.synchronizerState
                self.synchronizerStatusSnapshot = newValue.synchronizerStatusSnapshot
                self.shieldedBalance = newValue.shieldedBalance
                self.transparentBalance = newValue.transparentBalance
                self.latestFiatPrice = newValue.latestFiatPrice
                self.latestMinedHeight = newValue.latestMinedHeight
                self.expectingZatoshi = newValue.expectingZatoshi
                self.requiredTransactionConfirmations = newValue.requiredTransactionConfirmations
                self.walletEvents = newValue.walletEvents
            }
        }
        
        var transfer: Transfer.State {
            get {
                var state = transferState
                state.shieldedBalance = shieldedBalance
                state.unifiedAddress = unifiedAddress
                state.latestFiatPrice = latestFiatPrice
                return state
            }
            
            set {
                self.transferState = newValue
                self.shieldedBalance = newValue.shieldedBalance
                self.unifiedAddress = newValue.unifiedAddress
                self.latestFiatPrice = newValue.latestFiatPrice
            }
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case cancelSynchronizerUpdates
        case cantStartSync(ZcashError)
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case fetchLatestFiatPrice
        case latestFiatResponse(Double?)
        case listenForSynchronizerUpdates
        case onAppear
        case rescanDone(ZcashError? = nil)
        case settings(NighthawkSettings.Action)
        case synchronizerStateChanged(SynchronizerState)
        case transfer(Transfer.Action)
        case updateWalletEvents([WalletEvent])
        case wallet(Wallet.Action)
        
        public enum Alert: Equatable {}
        
        public enum Delegate: Equatable {
            case setLatestFiatPrice(Double?)
            case unifiedAddressResponse(UnifiedAddress?)
        }
    }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case addresses(Addresses)
        case autoshield(Autoshield)
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
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.wallet, action: \.wallet) {
            Wallet()
        }
        
        Scope(state: \.transfer, action: \.transfer) {
            Transfer()
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
                guard state.latestFiatPrice == nil, state.preferredCurrency != . off else { return .none }
                return .run { [preferredCurrency = state.preferredCurrency] send in
                    let price = try? await fiatPriceClient.getZcashPrice(preferredCurrency)
                    await send(.latestFiatResponse(price))
                    await send(.delegate(.setLatestFiatPrice(price)))
                }
            case let .latestFiatResponse(price):
                state.latestFiatPrice = price
                return .none
            case .onAppear:
                state.requiredTransactionConfirmations = zcashSDKEnvironment.requiredTransactionConfirmations
                UIApplication.shared.isIdleTimerDisabled = userStoredPreferences.screenMode() == .keepOn
                return .concatenate(
                    .send(.fetchLatestFiatPrice),
                    .send(.listenForSynchronizerUpdates)
                )
            case let .rescanDone(error):
                userStoredPreferences.setIsFirstSync(true)
                if let error {
                    state.alert = .rescanFailed(error.toZcashError())
                    return .none
                } else {
                    if let eventsCache = URL.latestEventsCache(for: zcashSDKEnvironment.network.networkType) {
                        try? fileManager.removeItem(eventsCache)
                    }
                    return .run { send in
                        do {
                            try await sdkSynchronizer.start(false)
                            await send(.cancelSynchronizerUpdates)
                            await send(.listenForSynchronizerUpdates)
                        } catch {
                            await send(.cantStartSync(error.toZcashError()))
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
                let snapshot = SyncStatusSnapshot.snapshotFor(state: latestState.syncStatus)
                guard snapshot != state.synchronizerStatusSnapshot else {
                    return .none
                }
                state.synchronizerState = latestState
                state.synchronizerStatusSnapshot = snapshot
                let spendableSapling = latestState.accountBalance?.saplingBalance.spendableValue ?? .zero
                let spendableOrchard = latestState.accountBalance?.orchardBalance.spendableValue ?? .zero
                let transparentBalance = latestState.accountBalance?.unshielded ?? .zero
                state.shieldedBalance = spendableSapling + spendableOrchard
                state.transparentBalance = transparentBalance
                let totalSapling = latestState.accountBalance?.saplingBalance.total() ?? .zero
                let totalOrchard = latestState.accountBalance?.orchardBalance.total() ?? .zero
                state.totalBalance = totalSapling + totalOrchard + transparentBalance
                
                if latestState.syncStatus == .upToDate {
                    userStoredPreferences.setIsFirstSync(false)
                    state.latestMinedHeight = sdkSynchronizer.latestState().latestBlockHeight
                    
                    // Detect if there are any expected funds
                    let availableBalance = state.shieldedBalance + state.transparentBalance
                    if state.totalBalance != availableBalance && (state.totalBalance - availableBalance) != state.expectingZatoshi {
                        state.expectingZatoshi = state.totalBalance - availableBalance
                        state.toast = .expectingFunds
                    }
                    
                    // Show autoshield, if needed
                    if !userStoredPreferences.hasShownAutoshielding() && state.transparentBalance >= .autoshieldingThreshold {
                        userStoredPreferences.setHasShownAutoshielding(true)
                        state.destination = .autoshield(.init())
                    }
                    
                    return .run { send in
                        // Re-fetch the UA, as sometimes it is unavailable when synchronizer first starts
                        let ua = try? await sdkSynchronizer.getUnifiedAddress(0)
                        await send(.delegate(.unifiedAddressResponse(ua)))
                        
                        // Populate wallet events
                        if let events = try? await sdkSynchronizer.getAllTransactions() {
                            let isBandit = events.contains(
                                where: { event in
                                    event.transaction.address == zcashSDKEnvironment.banditAddress &&
                                    event.transaction.zecAmount >= zcashSDKEnvironment.banditAmount
                                }
                            )
                            userStoredPreferences.setIsBandit(isBandit)
                            await send(.updateWalletEvents(events))
                        }
                    }
                }
                
                return .none
            case let .updateWalletEvents(walletEvents):
                let chainTip = sdkSynchronizer.latestState().latestBlockHeight + 1
                
                // Cache two latest events
                let events = IdentifiedArrayOf(uniqueElements: walletEvents.sortedEvents(with: chainTip))
                if let cache = URL.latestEventsCache(for: zcashSDKEnvironment.network.networkType) {
                    let latest = IdentifiedArray(events.prefix(2)).elements
                    if let data = try? JSONEncoder().encode(latest) {
                        try? dataManager.save(data, cache)
                    }
                }
                
                state.walletEvents = IdentifiedArrayOf(uniqueElements: events)
                return .none
            case .alert, .binding, .delegate, .destination, .settings, .transfer, .wallet:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        addressesDelegateReducer()
        transferReducer()
        walletReducer()
        nighthawkSettingsReducer()
    }
    
    public init() {}
}

// MARK: - Addresses delegate
extension Home {
    func addressesDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .destination(.presented(.addresses(.delegate(delegateAction)))):
                switch delegateAction {
                case .showPartners:
                    state.destination = nil
                    state.selectedTab = .transfer
                    return .run { send in
                        // Slight delay to allow previous sheet to dismiss before presenting
                        try await clock.sleep(for: .seconds(0.005))
                        await send(.transfer(.topUpWalletTapped))
                    }
                }
            case .alert,
                 .binding,
                 .cancelSynchronizerUpdates,
                 .cantStartSync,
                 .delegate,
                 .destination,
                 .fetchLatestFiatPrice,
                 .latestFiatResponse,
                 .listenForSynchronizerUpdates,
                 .onAppear,
                 .rescanDone,
                 .settings,
                 .synchronizerStateChanged,
                 .transfer,
                 .updateWalletEvents,
                 .wallet:
                return .none
            }
        }
    }
}
