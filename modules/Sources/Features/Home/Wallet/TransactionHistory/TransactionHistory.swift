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
        public var walletEvents: IdentifiedArrayOf<WalletEvent>
        
        public init(walletEvents: IdentifiedArrayOf<WalletEvent>) {
            self.walletEvents = walletEvents
        }
    }
    
    public enum Action: Equatable {
        case delegate(Delegate)
        case viewTransactionDetailTapped(WalletEvent)
        
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
            case let .viewTransactionDetailTapped(walletEvent):
                return .send(.delegate(.showTransactionDetail(walletEvent)))
            }
        }
    }
    
    public init() {}
}
