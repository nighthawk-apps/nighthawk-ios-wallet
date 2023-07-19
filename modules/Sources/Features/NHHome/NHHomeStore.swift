//
//  NHHomeStore.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import Addresses
import ComposableArchitecture
import DiskSpaceChecker
import Foundation
import Models
import SDKSynchronizer
import Utils
import ZcashLightClientKit

public struct NHHomeReducer: ReducerProtocol {
    private enum CancelId { case timer }
    
    public struct State: Equatable {
        public enum Destination: Equatable, Hashable {
            case wallet
            case transfer
            case settings
        }
        
        @BindingState public var destination = Destination.wallet
        @PresentationState public var addresses: AddressesReducer.State?
        
        // Shared state
        public var requiredTransactionConfirmations = 0
        public var latestMinedHeight: BlockHeight?
        public var shieldedBalance: Balance
        public var transparentBalance: Balance
        public var synchronizerStatusSnapshot: SyncStatusSnapshot
        public var walletEvents = IdentifiedArrayOf<WalletEvent>()
        public var shouldShowAddresses = false

        // Tab states
        public var walletState: WalletReducer.State
        public var transferState: TransferReducer.State
        public var settingsState: NHSettingsReducer.State
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case addresses(PresentationAction<AddressesReducer.Action>)
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
    
    public init() {}
    
    public var body: some ReducerProtocol<State, Action> {
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
            case let .updateDestination(destination):
                state.destination = destination
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
            case .wallet(.viewAddressesTapped):
                state.addresses = .init()
                return .none
            case .transfer(.destination(.presented(.receive(.showQrCodeTapped)))):
                state.transfer.destination = nil
                return .task {
                    // Slight delay to allow previous sheet to dismiss before presenting
                    try await Task.sleep(seconds: 0.005)
                    return .wallet(.viewAddressesTapped)
                }
            case .transfer(.destination(.presented(.receive(.topUpWalletTapped)))):
                state.transfer.destination = nil
                return .task {
                    // Slight delay to allow previous sheet to dismiss before presenting
                    try await Task.sleep(seconds: 0.005)
                    return .transfer(.topUpWalletTapped)
                }
            case .addresses(.presented(.topUpWalletTapped)):
                state.addresses = nil
                state.destination = .transfer
                return .task {
                    // Slight delay to allow previous sheet to dismiss before presenting
                    try await Task.sleep(seconds: 0.005)
                    return .transfer(.topUpWalletTapped)
                }
            case .addresses, .binding, .debugMenuStartup, .settings, .transfer, .wallet:
                return .none
            }
        }
        .ifLet(\.$addresses, action: /Action.addresses) {
            AddressesReducer()
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
    
    func addressesStore() -> Store<PresentationState<AddressesReducer.State>, PresentationAction<AddressesReducer.Action>> {
        scope(state: \.$addresses, action: Action.addresses)
    }
}

// MARK: Placeholders
extension NHHomeReducer.State {
    public static var placeholder: Self {
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
