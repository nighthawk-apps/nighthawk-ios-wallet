//
//  SDKSynchronizerLive.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 15.11.2022.
//

import Foundation
import Combine
import ComposableArchitecture
import ZcashLightClientKit
import DatabaseFiles
import Models
import ZcashSDKEnvironment

extension SDKSynchronizerClient: DependencyKey {
    public static let liveValue: SDKSynchronizerClient = Self.live()
    
    public static func live(
        databaseFiles: DatabaseFilesClient = .liveValue
    ) -> Self {
        @Dependency (\.zcashSDKEnvironment) var zcashSDKEnvironment
                
        let network = zcashSDKEnvironment.network
        
        let initializer = Initializer(
            cacheDbURL: databaseFiles.cacheDbURLFor(network),
            fsBlockDbRoot: databaseFiles.fsBlockDbRootFor(network),
            generalStorageURL: databaseFiles.documentsDirectory(),
            dataDbURL: databaseFiles.dataDbURLFor(network), 
            torDirURL: databaseFiles.torDirURLFor(network),
            endpoint: zcashSDKEnvironment.endpoint,
            network: network,
            spendParamsURL: databaseFiles.spendParamsURLFor(network),
            outputParamsURL: databaseFiles.outputParamsURLFor(network),
            saplingParamsSourceURL: SaplingParamsSourceURL.default,
            loggingPolicy: .noLogging
        )
        
        let synchronizer = SDKSynchronizer(initializer: initializer)
        
        return SDKSynchronizerClient(
            stateStream: { synchronizer.stateStream },
            eventStream: { synchronizer.eventStream },
            latestState: { synchronizer.latestState },
            prepareWith: { seedBytes, walletBirtday, walletMode in
                let result = try await synchronizer.prepare(with: seedBytes, walletBirthday: walletBirtday, for: walletMode)
                if result != .success { throw ZcashError.synchronizerNotPrepared }
            },
            start: { retry in try await synchronizer.start(retry: retry) },
            stop: { synchronizer.stop() },
            isSyncing: { synchronizer.latestState.syncStatus.isSyncing },
            isInitialized: { synchronizer.latestState.syncStatus != SyncStatus.unprepared },
            rewind: { synchronizer.rewind($0) },
            getAllTransactions: {
                let clearedTransactions = try await synchronizer.allTransactions()
                
                var clearedTxs: [WalletEvent] = []
                for clearedTransaction in clearedTransactions {
                    var transaction = TransactionState.init(
                        transaction: clearedTransaction,
                        memos: clearedTransaction.memoCount > 0 ? try await synchronizer.getMemos(for: clearedTransaction) : nil,
                        latestBlockHeight: synchronizer.latestState.latestBlockHeight
                    )
                    
                    let recipients = await synchronizer.getRecipients(for: clearedTransaction)
                    let tAddresses = recipients.allTransparent().addresses()
                    let zAddresses = recipients.allShielded().addresses()
                    
                    transaction.zAddress = zAddresses.first
                    transaction.tAddress = tAddresses.first
                    transaction.shielded = tAddresses.isEmpty
                    
                    clearedTxs.append(WalletEvent(transaction: transaction))
                }
                
                return clearedTxs
            },
            getUnifiedAddress: { try await synchronizer.getUnifiedAddress(accountIndex: $0) },
            getTransparentAddress: { try await synchronizer.getTransparentAddress(accountIndex: $0) },
            getSaplingAddress: { try await synchronizer.getSaplingAddress(accountIndex: $0) },
            sendTransaction: { spendingKey, amount, recipient, memo in
                let pendingTransaction = try await synchronizer.sendToAddress(
                    spendingKey: spendingKey,
                    zatoshi: amount,
                    toAddress: recipient,
                    memo: memo
                )
                return TransactionState(transaction: pendingTransaction)
            },
            shieldFunds: { spendingKey, memo, shieldingThreshold in
                let pendingTransaction = try await synchronizer.shieldFunds(
                    spendingKey: spendingKey,
                    memo: memo,
                    shieldingThreshold: shieldingThreshold
                )
                return TransactionState(transaction: pendingTransaction)
            },
            wipe: { synchronizer.wipe() },
            switchToEndpoint: { endpoint in
                try await synchronizer.switchTo(endpoint: endpoint)
            },
            proposeTransfer: { accountIndex, recipient, amount, memo in
                try await synchronizer.proposeTransfer(
                    accountIndex: accountIndex,
                    recipient: recipient,
                    amount: amount,
                    memo: memo
                )
            },
            createProposedTransactions: { proposal, spendingKey in
                let stream = try await synchronizer.createProposedTransactions(
                    proposal: proposal,
                    spendingKey: spendingKey
                )
                
                let transactionCount = proposal.transactionCount()
                var successCount = 0
                var iterator = stream.makeAsyncIterator()
                
                var txIds: [String] = []
                var statuses: [String] = []
                
                for _ in 1...transactionCount {
                    if let transactionSubmitResult = try await iterator.next() {
                        switch transactionSubmitResult {
                        case .success(txId: let id):
                            successCount += 1
                            txIds.append(id.toHexStringTxId())
                            statuses.append("success")
                        case let .grpcFailure(txId: id, error: error):
                            txIds.append(id.toHexStringTxId())
                            statuses.append(error.localizedDescription)
                        case let .submitFailure(txId: id, code: code, description: description):
                            txIds.append(id.toHexStringTxId())
                            statuses.append("code: \(code) desc: \(description)")
                        case .notAttempted(txId: let id):
                            txIds.append(id.toHexStringTxId())
                            statuses.append("notAttempted")
                        }
                    }
                }
                
                if successCount == 0 {
                    return .failure
                } else if successCount == transactionCount {
                    return .success
                } else {
                    return .partial(txIds: txIds, statuses: statuses)
                }
            },
            proposeShielding: { accountIndex, shieldingThreshold, memo, transparentReceiver in
                try await synchronizer.proposeShielding(
                    accountIndex: accountIndex,
                    shieldingThreshold: shieldingThreshold,
                    memo: memo,
                    transparentReceiver: transparentReceiver
                )
            }
        )
    }
}

private extension Array where Element == TransactionRecipient {
    func allShielded() -> Self {
        compactMap {
            if case let .address(address) = $0 {
                if case .unified = address {
                    return $0
                } else if case .sapling = address {
                    return $0
                }
                
                return nil
            } else {
                return nil
            }
        }
    }
    
    func allTransparent() -> Self {
        compactMap {
            if case let .address(address) = $0 {
                if case .transparent = address {
                    return $0
                }
                
                return nil
            } else {
                return nil
            }
        }
    }
    
    func addresses() -> [String] {
        compactMap {
            if case let .address(recipient) = $0 {
                return recipient.stringEncoded
            }
            
            return nil
        }
    }
}
