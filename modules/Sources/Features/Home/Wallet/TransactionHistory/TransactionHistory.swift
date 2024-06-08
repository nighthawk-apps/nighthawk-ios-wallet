//
//  TransactionHistory.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import ComposableArchitecture
import DiskSpaceChecker
import Models
import SDKSynchronizer
import UserPreferencesStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct TransactionHistory: Reducer {
    private enum CancelId { case timer }
    
    public struct State: Equatable {
        public var walletEvents: IdentifiedArrayOf<WalletEvent>
        public var synchronizerStatusSnapshot: SyncStatusSnapshot = .default
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
        
        public init(
            latestFiatPrice: Double?,
            initialEvents: IdentifiedArrayOf<WalletEvent> = []
        ) {
            self.latestFiatPrice = latestFiatPrice
            self.walletEvents = initialEvents
        }
    }
    
    public enum Action: Equatable {
        case delegate(Delegate)
        case onAppear
        case synchronizerStateChanged(SynchronizerState)
        case viewTransactionDetailTapped(WalletEvent)
        case updateWalletEvents([WalletEvent])
        
        public enum Delegate: Equatable {
            case handleDiskFull
            case showTransactionDetail(WalletEvent)
        }
    }
    
    @Dependency(\.diskSpaceChecker) var diskSpaceChecker
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironement
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .onAppear:
                if diskSpaceChecker.hasEnoughFreeSpaceForSync() {
                    return .publisher {
                        sdkSynchronizer.stateStream()
                            .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                            .map(Action.synchronizerStateChanged)
                    }
                    .cancellable(id: CancelId.timer, cancelInFlight: true)
                } else {
                    return .send(.delegate(.handleDiskFull))
                }
            case .synchronizerStateChanged(let latestState):
                let snapshot = SyncStatusSnapshot.snapshotFor(state: latestState.syncStatus)
                guard snapshot != state.synchronizerStatusSnapshot else {
                    return .none
                }
                
                state.synchronizerStatusSnapshot = snapshot
                if latestState.syncStatus == .upToDate {
                    return .run { send in
                        if let events = try? await sdkSynchronizer.getAllTransactions() {
                            await send(.updateWalletEvents(events))
                        }
                    }
                }
                
                return .none
            case let .updateWalletEvents(events):
                let chainTip = sdkSynchronizer.latestState().latestBlockHeight + 1
                
                let sortedWalletEvents = events
                    .sorted(by: { lhs, rhs in
                        var lhsHeight = chainTip
                        
                        if let lhsMinedHeight = lhs.transaction.minedHeight {
                            lhsHeight = lhsMinedHeight
                        } else if let lhsExpiredHeight = lhs.transaction.expiryHeight, lhsExpiredHeight > 0 {
                            lhsHeight = lhsExpiredHeight
                        }
                        
                        var rhsHeight = chainTip
                        if let rhsMinedHeight = rhs.transaction.minedHeight {
                            rhsHeight = rhsMinedHeight
                        } else if let rhsExpiredHeight = rhs.transaction.expiryHeight, rhsExpiredHeight > 0 {
                            rhsHeight = rhsExpiredHeight
                        }
                        
                        return lhsHeight > rhsHeight
                    })
                state.walletEvents = IdentifiedArrayOf(uniqueElements: sortedWalletEvents)
                return .none
            case let .viewTransactionDetailTapped(walletEvent):
                return .send(.delegate(.showTransactionDetail(walletEvent)))
            }
        }
    }
    
    public init() {}
}
