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

extension SDKSynchronizerClient {
    public static func live(
        databaseFiles: DatabaseFilesClient = .liveValue,
        environment: ZcashSDKEnvironment = .liveValue,
        network: ZcashNetwork
    ) -> Self {
        let initializer = Initializer(
            cacheDbURL: databaseFiles.cacheDbURLFor(network),
            fsBlockDbRoot: databaseFiles.fsBlockDbRootFor(network),
            generalStorageURL: databaseFiles.documentsDirectory(),
            dataDbURL: databaseFiles.dataDbURLFor(network),
            endpoint: environment.endpoint(network),
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
            getShieldedBalance: { synchronizer.latestState.shieldedBalance },
            getTransparentBalance: { synchronizer.latestState.transparentBalance },
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
                    let addresses = recipients.compactMap {
                        if case let .address(address) = $0 {
                            return address
                        } else {
                            return nil
                        }
                    }
                    
                    transaction.zAddress = addresses.first?.stringEncoded
                    
                    clearedTxs.append(
                        WalletEvent(
                            id: transaction.id,
                            state: .transaction(transaction),
                            timestamp: transaction.timestamp
                        )
                    )
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
            wipe: { synchronizer.wipe() }
        )
    }
}
