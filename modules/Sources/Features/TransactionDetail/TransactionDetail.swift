//
//  TransactionDetail.swift
//  
//
//  Created by Matthew Watt on 7/14/23.
//

import ComposableArchitecture
import DerivationTool
import DiskSpaceChecker
import Foundation
import Generated
import Models
import Pasteboard
import SDKSynchronizer
import UIComponents
import UIKit
import UserPreferencesStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct TransactionDetail: Reducer {
    private enum CancelId { case timer }
    
    public struct State: Equatable {
        public enum Toast: Equatable {
            case replyToCopied
        }
        
        @PresentationState public var alert: AlertState<Action.Alert>?
        @BindingState public var toast: Toast?
        public var latestMinedHeight: BlockHeight? = .zero
        public var requiredTransactionConfirmations: Int = .zero
        public var walletEvent: WalletEvent
        public var networkType: NetworkType
        public var latestFiatPrice: Double?
        public var isLoaded = false
        
        public var address: String? { walletEvent.transaction.address }
        public var confirmations: BlockHeight { walletEvent.transaction.confirmationsWith(latestMinedHeight) }
        public var date: Date? {
            guard let timestamp = walletEvent.timestamp else { return nil }
            
            return Date(timeIntervalSince1970: timestamp)
        }
        public var fee: Zatoshi { walletEvent.transaction.fee }
        public var id: String { walletEvent.id }
        public var isSending: Bool { walletEvent.transaction.isSending }
        public var memo: Memo? { walletEvent.transaction.textMemo }
        public var minedHeight: BlockHeight? { walletEvent.transaction.minedHeight }
        public var shielded: Bool { walletEvent.transaction.shielded }
        public var status: TransactionState.Status { walletEvent.transaction.status }
        public var viewOnlineURL: URL? { walletEvent.transaction.viewOnlineURL(for: networkType) }
        public var viewRecipientOnlineURL: URL? { walletEvent.transaction.viewRecipientOnlineURL(for: networkType) }
        public var zecAmount: Zatoshi { walletEvent.transaction.zecAmount }
        public var preferredCurrency: NighthawkSetting.FiatCurrency {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return userStoredPreferences.fiatCurrency()
        }
        public var fiatConversion: (NighthawkSetting.FiatCurrency, Double)? {
            if let latestFiatPrice, preferredCurrency != .off {
                (preferredCurrency, latestFiatPrice)
            } else {
                nil
            }
        }
                
        public init(
            walletEvent: WalletEvent,
            networkType: NetworkType,
            latestFiatPrice: Double?
        ) {
            self.walletEvent = walletEvent
            self.networkType = networkType
            self.latestFiatPrice = latestFiatPrice
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case copyReplyTo
        case delegate(Delegate)
        case onAppear
        case synchronizerStateChanged(SynchronizerState)
        case warnBeforeLeavingApp(URL?)
        
        public enum Alert: Equatable {
            case openBlockExplorer(URL?)
        }
        
        public enum Delegate: Equatable {
            case handleDiskFull
        }
    }
    
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.diskSpaceChecker) var diskSpaceChecker
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case let .alert(.presented(.openBlockExplorer(blockExplorerURL))):
                if let url = blockExplorerURL {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            case .alert(.dismiss):
                return .none
            case .alert:
                return .none
            case .binding:
                return .none
            case .copyReplyTo:
                if !state.isSending, let memo = state.memo?.toString(), !memo.isEmpty {
                    let prefix = zcashSDKEnvironment.replyToPrefix
                    let components = memo.split(separator: prefix)
                    if components.count == 2 && derivationTool.isZcashAddress(String(components[1]), state.networkType) {
                        pasteboard.setString(String(components[1]).redacted)
                        state.toast = .replyToCopied
                    }
                }
                return .none
            case .delegate:
                return .none
            case .onAppear:
                state.isLoaded = sdkSynchronizer.latestState().syncStatus.isSynced
                state.latestMinedHeight = sdkSynchronizer.latestState().latestBlockHeight
                state.requiredTransactionConfirmations = zcashSDKEnvironment.requiredTransactionConfirmations
                if diskSpaceChecker.hasEnoughFreeSpaceForSync() {
                    return .publisher {
                        sdkSynchronizer.stateStream()
                            .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                            .map(Action.synchronizerStateChanged)
                    }
                    .cancellable(id: CancelId.timer, cancelInFlight: true)
                } else {
                    return .run { send in
                        await send(.delegate(.handleDiskFull))
                        await self.dismiss()
                    }
                }
            case .synchronizerStateChanged(let latestState):
                if latestState.syncStatus == .upToDate {
                    state.isLoaded = sdkSynchronizer.latestState().syncStatus.isSynced
                    state.latestMinedHeight = sdkSynchronizer.latestState().latestBlockHeight
                }
                return .none
            case .warnBeforeLeavingApp(let blockExplorerURL):
                state.alert = AlertState.warnBeforeLeavingApp(blockExplorerURL)
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    public init () {}
}

// MARK: Alerts

extension AlertState where Action == TransactionDetail.Action.Alert {
    public static func warnBeforeLeavingApp(_ blockExplorerURL: URL?) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWallet)
        } actions: {
            ButtonState(action: .openBlockExplorer(blockExplorerURL)) {
                TextState(L10n.Nighthawk.TransactionDetails.viewTxDetails)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWarning(blockExplorerURL?.host() ?? ""))
        }
    }
}
