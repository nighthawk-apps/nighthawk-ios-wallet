//
//  TransactionDetail.swift
//  
//
//  Created by Matthew Watt on 7/14/23.
//

import ComposableArchitecture
import DiskSpaceChecker
import Foundation
import Generated
import Models
import SDKSynchronizer
import UIComponents
import UIKit
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct TransactionDetail: Reducer {
    private enum CancelId { case timer }
    
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        public var latestMinedHeight: BlockHeight? = .zero
        public var requiredTransactionConfirmations: Int = .zero
        public var walletEvent: WalletEvent
        
        public var address: String? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.address
            }
            
            return nil
        }
        
        public var confirmations: BlockHeight {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.confirmationsWith(latestMinedHeight)
            }
            
            return 0
        }
        
        public var date: Date? {
            guard let timestamp = walletEvent.timestamp else { return nil }
            
            return Date(timeIntervalSince1970: timestamp)
        }
        
        public var fee: Zatoshi? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.fee
            }
            
            return nil
        }
        
        public var id: String? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.id
            }
            
            return nil
        }
        
        public var isSending: Bool {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.isSending
            }
            
            return false
        }
        
        public var memo: Memo? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.textMemo
            }
            
            return nil
        }
        
        public var minedHeight: BlockHeight? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.minedHeight
            }
            
            return nil
        }
        
        public var shielded: Bool {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.shielded
            }
            
            return false
        }
        
        public var status: TransactionState.Status? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.status
            }
            
            return nil
        }
        
        public var totalAmount: Zatoshi? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.totalAmount
            }
            
            return nil
        }
        
        public var viewOnlineURL: URL? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.viewOnlineURL
            }
            
            return nil
        }
        
        public var viewRecipientOnlineURL: URL? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.viewRecipientOnlineURL
            }
            
            return nil
        }
        
        public var zecAmount: Zatoshi? {
            if case let .transaction(transaction) = walletEvent.state {
                return transaction.zecAmount
            }
            
            return nil
        }
                
        public init(walletEvent: WalletEvent) {
            self.walletEvent = walletEvent
        }
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
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
    
    @Dependency(\.diskSpaceChecker) var diskSpaceChecker
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .alert(.presented(.openBlockExplorer(blockExplorerURL))):
                if let url = blockExplorerURL {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            case .alert(.dismiss):
                return .none
            case .delegate:
                return .none
            case .onAppear:
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
                    state.latestMinedHeight = sdkSynchronizer.latestState().latestBlockHeight
                }
                return .none
            case .warnBeforeLeavingApp(let blockExplorerURL):
                state.alert = AlertState.warnBeforeLeavingApp(blockExplorerURL)
                return .none
            }
        }
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
