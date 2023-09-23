//
//  Home.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import Addresses
import Autoshield
import ComposableArchitecture
import DiskSpaceChecker
import Foundation
import Models
import UserPreferencesStorage
import SDKSynchronizer
import UIKit
import Utils
import ZcashLightClientKit

public struct Home: Reducer {
    let zcashNetwork: ZcashNetwork
    
    private enum CancelId { case timer }
    
    public struct State: Equatable {
        public enum Tab: Equatable, Hashable {
            case wallet
            case transfer
            case settings
        }
        
        public enum Toast {
            case expectingFunds
        }
        
        @PresentationState public var destination: Destination.State?
        @BindingState public var selectedTab = Tab.wallet
        @BindingState public var toast: Toast?
        
        public var synchronizerFailedToStart = false
        public var synchronizerFailed: Bool {
            synchronizerFailedToStart || synchronizerStatusSnapshot.isSyncFailed
        }
        
        // Shared state
        public var requiredTransactionConfirmations = 0
        public var latestMinedHeight: BlockHeight?
        public var shieldedBalance: Balance = .init()
        public var transparentBalance: Balance = .init()
        public var expectingZatoshi: Zatoshi = .zero
        public var synchronizerState: SynchronizerState = .zero
        public var synchronizerStatusSnapshot: SyncStatusSnapshot = .default
        public var walletEvents = IdentifiedArrayOf<WalletEvent>()

        // Tab states
        public var walletState: Wallet.State = .init()
        public var transferState: Transfer.State = .init()
        public var settings: NighthawkSettings.State = .init()
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case onDisappear
        case settings(NighthawkSettings.Action)
        case synchronizerStateChanged(SynchronizerState)
        case transfer(Transfer.Action)
        case updateWalletEvents([WalletEvent])
        case wallet(Wallet.Action)
        
        public enum Delegate: Equatable {
            case showTransactionHistory
        }
    }
    
    public struct Destination: Reducer {
        let networkType: NetworkType
        
        public enum State:  Equatable {
            case addresses(Addresses.State)
            case alert(AlertState<Action.Alert>)
            case autoshield(Autoshield.State)
        }
        
        public enum Action: Equatable {
            case addresses(Addresses.Action)
            case alert(Alert)
            case autoshield(Autoshield.Action)
            
            public enum Alert: Equatable {}
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.addresses, action: /Action.addresses) {
                Addresses()
            }
            
            Scope(state: /State.autoshield, action: /Action.autoshield) {
                Autoshield(networkType: networkType)
            }
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.diskSpaceChecker) var diskSpaceChecker
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
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
                    return .publisher {
                        sdkSynchronizer.stateStream()
                            .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                            .map(Home.Action.synchronizerStateChanged)
                    }
                    .cancellable(id: CancelId.timer, cancelInFlight: true)
                } else {
                    state.destination = .alert(.notEnoughFreeDiskSpace())
                    return .none
                }
            case .onDisappear:
                return .cancel(id: CancelId.timer)
            case .synchronizerStateChanged(let latestState):
                let snapshot = SyncStatusSnapshot.nhSnapshotFor(state: latestState.syncStatus)
                guard snapshot != state.synchronizerStatusSnapshot else {
                    return .none
                }
                state.synchronizerState = latestState
                state.synchronizerStatusSnapshot = snapshot
                state.shieldedBalance = latestState.shieldedBalance.redacted
                state.transparentBalance = latestState.transparentBalance.redacted
                
                if latestState.syncStatus == .upToDate {
                    state.latestMinedHeight = sdkSynchronizer.latestState().latestBlockHeight
                    
                    // Detect if there are any expected funds
                    let totalBalance = state.shieldedBalance.data.total + state.transparentBalance.data.total
                    let availableBalance = state.shieldedBalance.data.verified + state.transparentBalance.data.verified
                    if totalBalance != availableBalance && (totalBalance - availableBalance) != state.expectingZatoshi {
                        state.expectingZatoshi = totalBalance - availableBalance
                        state.toast = .expectingFunds
                    }
                    
                    return .run { send in
                        if let events = try? await sdkSynchronizer.getAllTransactions() {
                            await send(.updateWalletEvents(events))
                        }
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
            case .binding, .delegate, .destination, .settings, .transfer, .wallet:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination(networkType: zcashNetwork.networkType)
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
            case .binding,
                 .delegate,
                 .destination,
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
            state.synchronizerState = synchronizerState
            state.synchronizerStatusSnapshot = synchronizerStatusSnapshot
            state.shieldedBalance = shieldedBalance
            state.transparentBalance = transparentBalance
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
            return state
        }
        
        set {
            self.transferState = newValue
            self.shieldedBalance = newValue.shieldedBalance
        }
    }
}
