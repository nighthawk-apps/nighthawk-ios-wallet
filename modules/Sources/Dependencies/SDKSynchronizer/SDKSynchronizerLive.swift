//
//  SDKSynchronizerLive.swift
//  stealth
//
//  Live implementation wrapping DarkFi Rust core via UniFFI.
//  Uses DarkfiWalletHandle from blackhawk.swift.
//

import Combine
import ComposableArchitecture
import DarkfiCore
import Foundation
import Models
import UserPreferencesStorage
import Utils
import WalletStorage

// MARK: - Live Implementation

extension SDKSynchronizerClient: DependencyKey {
    public static let liveValue: SDKSynchronizerClient = Self(
        stateStream: {
            WalletHandleManager.shared.stateStream
        },
        latestState: {
            WalletHandleManager.shared.latestState
        },
        prepareWith: { seed, birthday, mode in
            try WalletHandleManager.shared.prepare(seed: seed, birthday: birthday, mode: mode)
        },
        start: { _ in
            guard let handle = WalletHandleManager.shared.handle else { return }

            // Trigger initial sync off the cooperative pool, then poll Rust's background sync thread.
            do {
                let (snapshot, balance, lightState) = try await Task.detached(priority: .userInitiated) {
                    let snap = try handle.refreshNow()
                    let bal = try handle.confirmedBalanceAtomic()
                    let light = handle.lightSyncSnapshot()
                    return (snap, bal, light)
                }.value

                let derivedStatus = WalletHandleManager.deriveSyncStatus(
                    light: lightState,
                    fallback: WalletHandleManager.shared.latestState.syncStatus
                )
                let tip = max(BlockHeight(snapshot.chainTip), UInt32(truncatingIfNeeded: max(0, lightState.chainTip)))
                WalletHandleManager.shared.updateState(SynchronizerState(
                    syncStatus: derivedStatus,
                    confirmedBalance: balance,
                    latestBlockHeight: tip,
                    activeSyncMethod: DarkfiSyncMethod(lightState.syncMethod),
                    fallbackReason: String(describing: lightState.fallbackReason),
                    fallbackUserMessage: lightState.fallbackUserMessage,
                    lightwalletdConnected: SynchronizerState.lightwalletdLive(lightState.status),
                    lightStatusMessage: lightState.statusMessage
                ))
                WalletHandleManager.shared.startPolling()
            } catch {
                let fallbackBalance = (try? handle.confirmedBalanceAtomic()) ?? WalletHandleManager.shared.latestState.confirmedBalance
                let lightState = handle.lightSyncSnapshot()
                WalletHandleManager.shared.updateState(SynchronizerState(
                    syncStatus: .error(error.localizedDescription),
                    confirmedBalance: fallbackBalance,
                    latestBlockHeight: WalletHandleManager.shared.latestState.latestBlockHeight,
                    activeSyncMethod: DarkfiSyncMethod(lightState.syncMethod),
                    fallbackReason: String(describing: lightState.fallbackReason),
                    fallbackUserMessage: lightState.fallbackUserMessage,
                    lightwalletdConnected: false,
                    lightStatusMessage: lightState.statusMessage.isEmpty ? error.localizedDescription : lightState.statusMessage
                ))
                WalletHandleManager.shared.startPolling()
            }
        },
        stop: {
            WalletHandleManager.shared.stopPolling()
            WalletHandleManager.shared.updateState(SynchronizerState(
                syncStatus: .stopped,
                confirmedBalance: WalletHandleManager.shared.latestState.confirmedBalance,
                latestBlockHeight: WalletHandleManager.shared.latestState.latestBlockHeight
            ))
        },
        isWalletPrepared: {
            WalletHandleManager.shared.handle != nil
        },
        refreshNow: {
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            let (snapshot, balance, lightState) = try await Task.detached(priority: .userInitiated) {
                let snap = try handle.refreshNow()
                let bal = (try? handle.confirmedBalanceAtomic()) ?? WalletHandleManager.shared.latestState.confirmedBalance
                let light = handle.lightSyncSnapshot()
                return (snap, bal, light)
            }.value
            let derivedStatus = WalletHandleManager.deriveSyncStatus(
                light: lightState,
                fallback: WalletHandleManager.shared.latestState.syncStatus
            )
            let tip = max(BlockHeight(snapshot.chainTip), UInt32(truncatingIfNeeded: max(0, lightState.chainTip)))
            WalletHandleManager.shared.updateState(SynchronizerState(
                syncStatus: derivedStatus,
                confirmedBalance: balance,
                latestBlockHeight: tip,
                activeSyncMethod: DarkfiSyncMethod(lightState.syncMethod),
                fallbackReason: String(describing: lightState.fallbackReason),
                fallbackUserMessage: lightState.fallbackUserMessage,
                lightwalletdConnected: SynchronizerState.lightwalletdLive(lightState.status),
                lightStatusMessage: lightState.statusMessage
            ))
        },
        getConfirmedBalance: {
            guard let handle = WalletHandleManager.shared.handle else { return 0 }
            return (try? handle.confirmedBalanceAtomic()) ?? 0
        },
        getReceiveAddress: { account in
            guard let handle = WalletHandleManager.shared.handle else { return nil }
            if let addresses = try? handle.listAddresses(), account < addresses.count {
                return DarkfiAddress(stringEncoded: addresses[account])
            }
            // Fall back to primary address
            guard let addr = try? handle.primaryDepositAddress() else { return nil }
            return DarkfiAddress(stringEncoded: addr)
        },
        getAddress: {
            guard let handle = WalletHandleManager.shared.handle else { return nil }
            guard let addr = try? handle.primaryDepositAddress() else { return nil }
            return DarkfiAddress(stringEncoded: addr)
        },
        generateNewAddress: {
            guard let handle = WalletHandleManager.shared.handle else {
                throw DarkfiError(message: "Wallet not initialized")
            }
            return try handle.generateNewAddress()
        },
        getAllTransactions: {
            guard let handle = WalletHandleManager.shared.handle else { return [] }
            let records = try handle.listTransactions()
            return records.map { record in
                let minedHeight = record.blockHeight >= 0 ? BlockHeight(record.blockHeight) : nil
                let blockTime = minedHeight.flatMap { BlockTimestampIndex.timestamp(forBlockHeight: $0) }
                return DarkfiTransactionOverview(
                    rawId: record.txHash,
                    minedHeight: minedHeight,
                    timestampEpochSeconds: blockTime ?? BlockTimestampIndex.timestamp(forTxHash: record.txHash),
                    totalAtomicValue: record.netValueAtomic,
                    fee: record.feeAtomic,
                    isSending: record.isSent,
                    status: record.status,
                    contractSummary: record.contractSummary,
                    recipientAddress: record.recipientAddress,
                    memo: try? handle.transactionPaymentMemo(txHash: record.txHash),
                    syncMethod: DarkfiSyncMethod(record.syncMethod)
                )
            }
        },
        proposeTransfer: { _, recipient, amount, memo, tokenId in
            guard let handle = WalletHandleManager.shared.handle else {
                throw DarkfiError(message: "Wallet not initialized")
            }

            guard case .address(let recipientAddr) = recipient else {
                throw DarkfiError(message: "Invalid recipient")
            }

            let memoText: String? = memo?.text
            // Rust FFI parses whole-DRK decimals (8 places), not atomic Int64 strings.
            let amountDecimal = amount.inputDecimalString()
            let tokenBalances = (try? handle.listTokenBalances()) ?? []
            let effectiveTokenId = WalletHandleManager.normalizeTokenId(tokenId, tokenBalances: tokenBalances)
            // Check balance before proposing
            let balance = try handle.confirmedBalanceAtomic()
            let fee = try handle.estimateTransferFee(
                recipientAddress: recipientAddr,
                amount: amountDecimal,
                tokenId: effectiveTokenId,
                paymentMemo: memoText
            )

            if let customTokenId = effectiveTokenId {
                let tokenBalance = tokenBalances
                    .first(where: { $0.tokenId == customTokenId })?.balanceAtomic ?? 0
                guard tokenBalance >= amount else {
                    throw DarkfiError(message: "Insufficient token balance. Available: \(tokenBalance), required: \(amount)")
                }
                guard balance >= fee else {
                    throw DarkfiError(message: "Insufficient DRK for fee. Available: \(balance), required fee: \(fee)")
                }
            } else {
                guard balance >= amount + fee else {
                    throw DarkfiError(message: "Insufficient balance. Available: \(balance), required: \(amount + fee) (amount + fee)")
                }
            }

            return Proposal(estimatedFee: fee)
        },
        estimateFee: { address, amount, tokenId in
            // Matches Rust `SCHEDULE_TRANSFER_FEE_ATOMIC` (5_000_000 atomic = 0.05 DRK).
            let scheduledFee: DrkAmount = 5_000_000
            guard let handle = WalletHandleManager.shared.handle else {
                return scheduledFee
            }
            let tokenBalances = (try? handle.listTokenBalances()) ?? []
            let effectiveTokenId = WalletHandleManager.normalizeTokenId(tokenId, tokenBalances: tokenBalances)
            return (try? handle.estimateTransferFee(
                recipientAddress: address.stringEncoded,
                amount: amount.inputDecimalString(),
                tokenId: effectiveTokenId,
                paymentMemo: nil
            )) ?? scheduledFee
        },
        sendTransaction: { _, amount, recipient, memo, tokenId in
            guard let handle = WalletHandleManager.shared.handle else {
                throw DarkfiError(message: "Wallet not initialized")
            }

            guard case .address(let recipientAddr) = recipient else {
                throw DarkfiError(message: "Invalid recipient")
            }

            // Build and broadcast — PerfOMR/OMD clue embedded in Rust by default.
            // Pass whole-DRK decimal string (not atomic) to match Rust parsers.
            let memoText: String? = memo?.text
            let amountDecimal = amount.inputDecimalString()
            let tokenBalances = (try? handle.listTokenBalances()) ?? []
            let effectiveTokenId = WalletHandleManager.normalizeTokenId(tokenId, tokenBalances: tokenBalances)
            let estimatedFee: Int64 = (try? handle.estimateTransferFee(
                recipientAddress: recipientAddr,
                amount: amountDecimal,
                tokenId: effectiveTokenId,
                paymentMemo: memoText
            )) ?? 5_000_000
            let txBytes = try handle.buildTransfer(
                recipientAddress: recipientAddr,
                amount: amountDecimal,
                tokenId: effectiveTokenId,
                paymentMemo: memoText
            )
            let txHash = try handle.broadcastTransfer(
                txBytes: txBytes,
                paymentMemo: memoText,
                recipientAddress: recipientAddr
            )

            // Refresh balance after send while preserving honest sync/fallback status.
            let newBalance = (try? handle.confirmedBalanceAtomic()) ?? 0
            let snapshot = (try? handle.syncSnapshot()) ?? DrkSyncSnapshot(scannedBlocks: 0, chainTip: 0)
            let lightState = handle.lightSyncSnapshot()
            let previousState = WalletHandleManager.shared.latestState
            let derivedStatus = WalletHandleManager.deriveSyncStatus(
                light: lightState,
                fallback: previousState.syncStatus
            )
            let preservedFallbackReason: String = {
                let current = String(describing: lightState.fallbackReason)
                return current == "none" && previousState.fallbackReason != "None"
                    ? previousState.fallbackReason
                    : current
            }()
            let preservedFallbackMsg = lightState.fallbackUserMessage.isEmpty
                ? previousState.fallbackUserMessage
                : lightState.fallbackUserMessage

            WalletHandleManager.shared.updateState(SynchronizerState(
                syncStatus: derivedStatus,
                confirmedBalance: newBalance,
                latestBlockHeight: max(BlockHeight(snapshot.chainTip), previousState.latestBlockHeight),
                activeSyncMethod: DarkfiSyncMethod(lightState.syncMethod),
                fallbackReason: preservedFallbackReason,
                fallbackUserMessage: preservedFallbackMsg,
                lightwalletdConnected: SynchronizerState.lightwalletdLive(lightState.status),
                lightStatusMessage: lightState.statusMessage.isEmpty ? previousState.lightStatusMessage : lightState.statusMessage
            ))

            let sentAt = Date().timeIntervalSince1970
            BlockTimestampIndex.note(txHash: txHash, sentAt: sentAt)
            return DarkfiTransactionOverview(
                rawId: txHash,
                timestampEpochSeconds: sentAt,
                totalAtomicValue: effectiveTokenId == nil ? (amount + estimatedFee) : amount,
                fee: estimatedFee,
                isSending: true,
                status: "Broadcasted",
                contractSummary: "Money::TransferV1",
                recipientAddress: recipientAddr,
                memo: memo?.text,
                // Trial decryption is the default. UnifOMR is only the path when
                // Advanced settings turned strict UnifOMR on.
                syncMethod: WalletSyncPrivacy.strictOmrOnly ? .unifOmr : .trialDecrypt
            )
        },
        // Wired to regenerated UniFFI bindings — thin conversion from FFI types to app models
        getTransactionMemo: { txHash in
            guard let handle = WalletHandleManager.shared.handle else { return nil }
            return try? handle.transactionPaymentMemo(txHash: txHash)
        },
        getTransactionRecipient: { txHash in
            guard let handle = WalletHandleManager.shared.handle else { return nil }
            return try? handle.transactionRecipient(txHash: txHash)
        },
        listDaos: {
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            let ffiDaos = try handle.listDaos()
            return ffiDaos.map { d in
                DaoBrief(
                    name: d.name,
                    bullaB58: d.bullaB58,
                    govTokenId: d.govTokenId,
                    quorumDisplay: d.quorumDisplay,
                    proposerLimitDisplay: d.proposerLimitDisplay,
                    approvalRatioPercent: d.approvalRatioPercent,
                    mintHeight: d.mintHeight >= 0 ? d.mintHeight : nil,
                    canPropose: d.canPropose,
                    canVote: d.canVote,
                    canExec: d.canExec
                )
            }
        },
        listProposals: { daoName in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            let ffiProposals = try handle.listProposals(daoName: daoName)
            return ffiProposals.map { p in
                ProposalBrief(
                    proposalBullaB58: p.proposalBullaB58,
                    daoName: p.daoName,
                    daoBullaB58: p.daoBullaB58,
                    authCallCount: Int(p.authCallCount),
                    durationBlockwindows: Int64(p.durationBlockwindows),
                    creationBlockwindow: Int64(p.creationBlockwindow),
                    mintHeight: p.mintHeight >= 0 ? p.mintHeight : nil,
                    execHeight: p.execHeight >= 0 ? p.execHeight : nil,
                    isExecuted: p.isExecuted,
                    summaryLine: p.summaryLine
                )
            }
        },
        getProposal: { bullaB58 in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            let d = try handle.getProposal(proposalBullaB58: bullaB58)
            let brief = ProposalBrief(
                proposalBullaB58: d.proposalBullaB58,
                daoName: d.daoName,
                daoBullaB58: d.daoBullaB58,
                authCallCount: Int(d.authCallCount),
                durationBlockwindows: Int64(d.durationBlockwindows),
                creationBlockwindow: Int64(d.creationBlockwindow),
                mintHeight: d.mintHeight >= 0 ? d.mintHeight : nil,
                execHeight: d.execHeight >= 0 ? d.execHeight : nil,
                isExecuted: d.isExecuted,
                summaryLine: d.summaryLine
            )
            return ProposalFull(
                brief: brief,
                proposeTxHash: d.proposeTxHash,
                execTxHash: d.execTxHash,
                hasPlaintextData: d.hasPlaintextData
            )
        },
        daoProposeTransfer: { daoName, durationBlockwindows, amount, tokenId, recipientAddress in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.daoProposeTransfer(
                daoName: daoName,
                durationBlockwindows: durationBlockwindows,
                amount: amount,
                tokenId: tokenId,
                recipientAddress: recipientAddress
            )
        },
        daoVote: { proposalBullaB58, voteYes in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.daoVote(
                proposalBullaB58: proposalBullaB58,
                voteYes: voteYes
            )
        },
        daoExec: { proposalBullaB58 in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.daoExec(proposalBullaB58: proposalBullaB58)
        },
        daoTreasury: { daoName in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.daoTreasury(daoName: daoName)
        },
        daoCreate: { name, proposerLimit, quorum, earlyExecQuorum, approvalRatio, govTokenId in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.daoCreate(
                name: name,
                proposerLimit: proposerLimit,
                quorum: quorum,
                earlyExecQuorum: earlyExecQuorum,
                approvalRatio: approvalRatio,
                govTokenId: govTokenId
            )
        },
        daoImport: { name, toml in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.daoImport(name: name, toml: toml)
        },
        daoFund: { daoName, amount, tokenId in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.daoFund(daoName: daoName, amount: amount, tokenId: tokenId)
        },
        daoExportRole: { daoName, role in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.daoExportRole(daoName: daoName, role: role)
        },
        tokenGenerate: { alias in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.tokenGenerate(alias: alias)
        },
        tokenMint: { tokenId, amount, recipient in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.tokenMint(tokenId: tokenId, amount: amount, recipientAddress: recipient)
        },
        tokenFreeze: { tokenId in
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.tokenFreeze(tokenId: tokenId)
        },
        listMintAuthorities: {
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            return try handle.listMintAuthorities().map {
                MintAuthorityBrief(tokenId: $0.tokenId, alias: $0.alias, frozen: $0.frozen)
            }
        },
        wipe: {
            WalletHandleManager.shared.wipe()
        },
        nukeLocalDatabases: {
            WalletHandleManager.shared.nukeLocalDatabases()
        },
        rewind: {
            guard let handle = WalletHandleManager.shared.handle else {
                return Fail(error: DarkfiError(message: "Wallet not initialized"))
                    .eraseToAnyPublisher()
            }

            return Future<Void, Error> { promise in
                Task.detached(priority: .userInitiated) {
                    do {
                        BlockTimestampIndex.reset()
                        // Real UniFFI rescan: rewind sync cursor, compact block cache, coins,
                        // Merkle tree, and transaction history back to genesis, then re-scan.
                        _ = try handle.handleReorgRecovery(rewindToHeight: 0)
                        WalletHandleManager.shared.updateState(SynchronizerState(
                            syncStatus: .syncing(progress: 0),
                            confirmedBalance: 0,
                            latestBlockHeight: 0,
                            activeSyncMethod: WalletHandleManager.shared.activeSyncMethod,
                            lightwalletdConnected: false,
                            lightStatusMessage: "Rescanning blockchain…"
                        ))
                        let snapshot = try handle.refreshNow()
                        let balance = (try? handle.confirmedBalanceAtomic()) ?? 0
                        let lightState = handle.lightSyncSnapshot()
                        let derivedStatus = WalletHandleManager.deriveSyncStatus(
                            light: lightState,
                            fallback: .syncing(progress: 0)
                        )
                        WalletHandleManager.shared.updateState(SynchronizerState(
                            syncStatus: derivedStatus,
                            confirmedBalance: balance,
                            latestBlockHeight: max(
                                BlockHeight(snapshot.chainTip),
                                UInt32(truncatingIfNeeded: max(0, lightState.chainTip))
                            ),
                            activeSyncMethod: DarkfiSyncMethod(lightState.syncMethod),
                            fallbackReason: String(describing: lightState.fallbackReason),
                            fallbackUserMessage: lightState.fallbackUserMessage,
                            lightwalletdConnected: SynchronizerState.lightwalletdLive(lightState.status),
                            lightStatusMessage: lightState.statusMessage
                        ))
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.eraseToAnyPublisher()
        },
        listTokenBalances: {
            guard let handle = WalletHandleManager.shared.handle else { return [] }
            let ffiBalances = (try? handle.listTokenBalances()) ?? []
            return ffiBalances.map { b in
                TokenBalanceInfo(
                    tokenId: b.tokenId,
                    displayLabel: b.displayLabel,
                    balanceAtomic: b.balanceAtomic
                )
            }
        }
    )
}

private enum SDKSynchronizerError: LocalizedError {
    case walletNotPrepared

    var errorDescription: String? {
        switch self {
        case .walletNotPrepared:
            return "Wallet not initialized. Connect to a DarkFi node under Settings → Change Server, then try again."
        }
    }
}
