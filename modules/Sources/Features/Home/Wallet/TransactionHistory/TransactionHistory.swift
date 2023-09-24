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
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct TransactionHistory: Reducer {
    private enum CancelId { case timer }
    
    public struct State: Equatable {
        public var walletEvents: IdentifiedArrayOf<WalletEvent> = []
        
        public init() {}
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
                if latestState.syncStatus == .upToDate {
                    return .run { send in
                        if let events = try? await sdkSynchronizer.getAllTransactions() {
                            await send(.updateWalletEvents(events))
                        }
                    }
                }
                
                return .none
            case let .updateWalletEvents(events):
                let sortedWalletEvents = events
                    .sorted(by: { lhs, rhs in
                        guard let lhsTimestamp = lhs.timestamp, let rhsTimestamp = rhs.timestamp else {
                            return false
                        }
                        return lhsTimestamp > rhsTimestamp
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