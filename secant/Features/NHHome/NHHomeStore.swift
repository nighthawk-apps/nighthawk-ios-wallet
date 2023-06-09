//
//  NHHomeStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import Foundation
import Models
import Utils
import ZcashLightClientKit

struct NHHomeReducer: ReducerProtocol {
    private enum CancelId {}
    
    struct State: Equatable {
        enum Destination: Equatable, Hashable {
            case wallet
            case transfer
            case settings
        }
        
        @BindingState var destination = Destination.wallet
        
        // Shared state
        var requiredTransactionConfirmations = 0
        var latestMinedHeight: BlockHeight?
        var shieldedBalance: Balance
        var transparentBalance: Balance
        var synchronizerStatusSnapshot: SyncStatusSnapshot
        var walletEvents = IdentifiedArrayOf<WalletEvent>()

        // Tab states
        var walletState: WalletReducer.State
        var transferState: TransferReducer.State
        var settingsState: NHSettingsReducer.State
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case debugMenuStartup
        case onAppear
        case onDisappear
        case settings(NHSettingsReducer.Action)
        case synchronizerStateChanged(SynchronizerState)
        case transfer(TransferReducer.Action)
        case updateDestination(NHHomeReducer.State.Destination)
        case wallet(WalletReducer.Action)
        case updateWalletEvents([WalletEvent])
    }
    
    @Dependency(\.diskSpaceChecker) var diskSpaceChecker
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Scope(state: \.wallet, action: /Action.wallet) {
            WalletReducer()
        }
        
        Scope(state: \.transfer, action: /Action.transfer) {
            TransferReducer()
        }
        
        Scope(state: \.settings, action: /Action.settings) {
            NHSettingsReducer()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.requiredTransactionConfirmations = zcashSDKEnvironment.requiredTransactionConfirmations
                
                if diskSpaceChecker.hasEnoughFreeSpaceForSync() {
                    let syncEffect = sdkSynchronizer.stateStream()
                        .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                        .map(NHHomeReducer.Action.synchronizerStateChanged)
                        .eraseToEffect()
                        .cancellable(id: CancelId.self, cancelInFlight: true)
                    return syncEffect
                } else {
                    // TODO: Handle not enough free disk space
                    return .none
//                    return EffectTask(value: .updateDestination(.notEnoughFreeDiskSpace))
                }
            case .onDisappear:
                return .cancel(id: CancelId.self)
            case .synchronizerStateChanged(let latestState):
                let snapshot = SyncStatusSnapshot.nhSnapshotFor(state: latestState.syncStatus)
                guard snapshot != state.synchronizerStatusSnapshot else {
                    return .none
                }
                state.synchronizerStatusSnapshot = snapshot
                state.shieldedBalance = latestState.shieldedBalance.redacted
                state.transparentBalance = latestState.transparentBalance.redacted
                
                if latestState.syncStatus.isSynced {
                    state.latestMinedHeight = sdkSynchronizer.latestScannedHeight()
                    return .task {
                        return .updateWalletEvents(try await sdkSynchronizer.getAllTransactions())
                    }
                }
                
                return .none
            case let .updateDestination(destination):
                state.destination = destination
                return .none
            case let .updateWalletEvents(walletEvents):
                let sortedWalletEvents = IdentifiedArrayOf<WalletEvent>.placeholder
                    .sorted(by: { lhs, rhs in
                        guard let lhsTimestamp = lhs.timestamp, let rhsTimestamp = rhs.timestamp else {
                            return false
                        }
                        return lhsTimestamp > rhsTimestamp
                    })
                state.walletEvents = IdentifiedArrayOf(uniqueElements: sortedWalletEvents)
                return .none
            case .binding, .debugMenuStartup, .settings, .transfer, .wallet:
                return .none
            }
        }
    }
}

// MARK: - Shared state synchronization
extension NHHomeReducer.State {
    var wallet: WalletReducer.State {
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
    
    var transfer: TransferReducer.State {
        get {
            var state = transferState
            return state
        }
        
        set {
            self.transferState = newValue
        }
    }
    
    var settings: NHSettingsReducer.State {
        get {
            var state = settingsState
            return state
        }
        
        set {
            self.settingsState = newValue
        }
    }
}

extension Store<NHHomeReducer.State, NHHomeReducer.Action> {
    func walletStore() -> Store<WalletReducer.State, WalletReducer.Action> {
        scope(state: \.wallet, action: Action.wallet)
    }
    
    func transferStore() -> Store<TransferReducer.State, TransferReducer.Action> {
        scope(state: \.transfer, action: Action.transfer)
    }
    
    func settingsStore() -> Store<NHSettingsReducer.State, NHSettingsReducer.Action> {
        scope(state: \.settings, action: Action.settings)
    }
}

// MARK: Placeholders
extension NHHomeReducer.State {
    static var placeholder: Self {
        .init(
            shieldedBalance: .init(),
            transparentBalance: .init(),
            synchronizerStatusSnapshot: .default,
            walletState: .placeholder,
            transferState: .placeholder,
            settingsState: .placeholder
        )
    }
}
