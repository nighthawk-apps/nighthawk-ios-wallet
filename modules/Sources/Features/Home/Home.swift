//
//  Home.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import Addresses
import ComposableArchitecture
import DiskSpaceChecker
import Foundation
import Models
import UserPreferencesStorage
import SDKSynchronizer
import UIKit
import Utils
import ZcashLightClientKit

public struct Home: ReducerProtocol {
    let zcashNetwork: ZcashNetwork
    
    private enum CancelId { case timer }
    
    public struct State: Equatable {
        public enum Destination: Equatable, Hashable {
            case wallet
            case transfer
            case settings
        }
        
        @BindingState public var destination = Destination.wallet
        @PresentationState public var addresses: Addresses.State?
        
        // Shared state
        public var requiredTransactionConfirmations = 0
        public var latestMinedHeight: BlockHeight?
        public var shieldedBalance: Balance = .init()
        public var transparentBalance: Balance = .init()
        public var synchronizerStatusSnapshot: SyncStatusSnapshot = .default
        public var walletEvents = IdentifiedArrayOf<WalletEvent>()

        // Tab states
        public var walletState: Wallet.State = .init()
        public var transferState: Transfer.State = .init()
        public var settingsState: NighthawkSettings.State = .init()
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case addresses(PresentationAction<Addresses.Action>)
        case onAppear
        case onDisappear
        case settings(NighthawkSettings.Action)
        case synchronizerStateChanged(SynchronizerState)
        case transfer(Transfer.Action)
        case wallet(Wallet.Action)
        case updateWalletEvents([WalletEvent])
    }
    
    @Dependency(\.diskSpaceChecker) var diskSpaceChecker
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Scope(state: \.wallet, action: /Action.wallet) {
            Wallet()
        }
        
        Scope(state: \.transfer, action: /Action.transfer) {
            Transfer(networkType: zcashNetwork.networkType)
        }
        
        Scope(state: \.settings, action: /Action.settings) {
            NighthawkSettings(zcashNetwork: zcashNetwork)
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.requiredTransactionConfirmations = zcashSDKEnvironment.requiredTransactionConfirmations
                UIApplication.shared.isIdleTimerDisabled = userStoredPreferences.screenMode() == .keepOn
                
                if diskSpaceChecker.hasEnoughFreeSpaceForSync() {
                    let syncEffect = sdkSynchronizer.stateStream()
                        .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                        .map(Home.Action.synchronizerStateChanged)
                        .eraseToEffect()
                        .cancellable(id: CancelId.timer, cancelInFlight: true)
                    return syncEffect
                } else {
                    // TODO: Handle not enough free disk space
                    return .none
//                    return EffectTask(value: .updateDestination(.notEnoughFreeDiskSpace))
                }
            case .onDisappear:
                return .cancel(id: CancelId.timer)
            case .synchronizerStateChanged(let latestState):
                let snapshot = SyncStatusSnapshot.nhSnapshotFor(state: latestState.syncStatus)
                guard snapshot != state.synchronizerStatusSnapshot else {
                    return .none
                }
                state.synchronizerStatusSnapshot = snapshot
                state.shieldedBalance = latestState.shieldedBalance.redacted
                state.transparentBalance = latestState.transparentBalance.redacted
                
                if latestState.syncStatus == .upToDate {
                    state.latestMinedHeight = sdkSynchronizer.latestScannedHeight()
                    return .task {
                        return .updateWalletEvents(try await sdkSynchronizer.getAllTransactions())
                    }
                }
                
                return .none
            case let .updateWalletEvents(walletEvents):
                let sortedWalletEvents = walletEvents
                    .sorted(by: { lhs, rhs in
                        guard let lhsTimestamp = lhs.timestamp, let rhsTimestamp = rhs.timestamp else {
                            return false
                        }
                        return lhsTimestamp > rhsTimestamp
                    })
                state.walletEvents = IdentifiedArrayOf(uniqueElements: sortedWalletEvents)
                return .none
            case .addresses, .binding, .settings, .transfer, .wallet:
                return .none
            }
        }
        .ifLet(\.$addresses, action: /Action.addresses) {
            Addresses()
        }
        
        addressesDelegateReducer()
        transferReducer()
        walletReducer()
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }
}

// MARK: - Addresses delegate
extension Home {
    func addressesDelegateReducer() -> Reduce<Home.State, Home.Action> {
        Reduce { state, action in
            switch action {
            case let .addresses(.presented(.delegate(delegateAction))):
                switch delegateAction {
                case .showPartners:
                    state.addresses = nil
                    state.destination = .transfer
                    return .task {
                        // Slight delay to allow previous sheet to dismiss before presenting
                        try await Task.sleep(seconds: 0.005)
                        return .transfer(.topUpWalletTapped)
                    }
                }
            case .addresses,
                 .binding,
                 .onAppear,
                 .onDisappear,
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

// MARK: - Shared state synchronization
extension Home.State {
    var wallet: Wallet.State {
        get {
            var state = walletState
            state.synchronizerStatusSnapshot = synchronizerStatusSnapshot
            state.shieldedBalance = shieldedBalance
            state.transparentBalance = transparentBalance
            state.latestMinedHeight = latestMinedHeight
            state.requiredTransactionConfirmations = requiredTransactionConfirmations
            state.walletEvents = walletEvents
            return state
        }
        
        set {
            self.walletState = newValue
            self.synchronizerStatusSnapshot = newValue.synchronizerStatusSnapshot
            self.shieldedBalance = newValue.shieldedBalance
            self.transparentBalance = newValue.transparentBalance
            self.latestMinedHeight = newValue.latestMinedHeight
            self.requiredTransactionConfirmations = newValue.requiredTransactionConfirmations
            self.walletEvents = newValue.walletEvents
        }
    }
    
    var transfer: Transfer.State {
        get {
            var state = transferState
            state.shieldedBalance = shieldedBalance
            return state
        }
        
        set {
            self.transferState = newValue
            self.shieldedBalance = newValue.shieldedBalance
        }
    }
    
    var settings: NighthawkSettings.State {
        get {
            var state = settingsState
            return state
        }
        
        set {
            self.settingsState = newValue
        }
    }
}
