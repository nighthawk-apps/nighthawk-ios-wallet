//
//  SDKSynchronizerLive.swift
//  stealth
//
//  Live implementation wrapping DarkFi Rust core via UniFFI.
//  Uses DarkfiWalletHandle from darkfi_mobile_ffi.swift.
//

import Combine
import ComposableArchitecture
import DarkfiCore
import Foundation
import Utils

// MARK: - Wallet Handle Manager

/// Singleton manager for the DarkFi wallet handle.
/// The handle is created once during wallet preparation and reused.
private final class WalletHandleManager: @unchecked Sendable {
    static let shared = WalletHandleManager()
    
    private let lock = NSLock()
    private var _handle: DarkfiWalletHandle?
    private let stateSubject = CurrentValueSubject<SynchronizerState, Never>(.zero)
    
    var handle: DarkfiWalletHandle? {
        lock.lock()
        defer { lock.unlock() }
        return _handle
    }
    
    var stateStream: AnyPublisher<SynchronizerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    var latestState: SynchronizerState {
        stateSubject.value
    }
    
    /// Default darkfid JSON-RPC endpoint (testnet 0.3)
    static let defaultDarkfidEndpoint = "tcp://127.0.0.1:18345"
    
    /// UserDefaults key for custom server endpoint (set by ChangeServer feature)
    static let serverEndpointKey = "darkfi_server_endpoint"
    
    func prepare(seed: [UInt8], birthday: BlockHeight, mode: WalletInitMode) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let walletDbPath = docs.appendingPathComponent("darkfi_wallet.db").path
        let cachePath = docs.appendingPathComponent("darkfi_cache").path
        
        // Create cache dir if needed
        try? FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true)
        
        // Convert seed bytes to mnemonic words.
        // The seed bytes are the UTF-8 encoded mnemonic phrase string
        // (e.g. "word1 word2 word3 ...").
        let mnemonicString = String(data: Data(seed), encoding: .utf8) ?? ""
        let words = mnemonicString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map(String.init)
        
        guard !words.isEmpty else {
            throw DarkfiWalletNativeError.InvalidBootstrapConfig(
                message: "Empty mnemonic phrase — cannot initialize wallet"
            )
        }
        
        // Read user-configured server endpoint (from ChangeServer settings),
        // or fall back to the default local darkfid RPC.
        let endpoint = UserDefaults.standard.string(
            forKey: WalletHandleManager.serverEndpointKey
        ) ?? WalletHandleManager.defaultDarkfidEndpoint
        
        let config = DrkBootstrapConfig(
            network: "testnet",  // DarkFi testnet 0.3
            mnemonic: words,
            walletDbPath: walletDbPath,
            cachePath: cachePath,
            walletPass: "",
            darkfidEndpointUrl: endpoint,
            birthdayHeight: Int64(birthday)
        )
        
        _handle = try DarkfiWalletHandle(config: config)
        
        // Update state to reflect initialization
        stateSubject.send(SynchronizerState(
            syncStatus: .unprepared,
            confirmedBalance: 0,
            latestBlockHeight: 0
        ))
    }
    
    func updateState(_ state: SynchronizerState) {
        stateSubject.send(state)
    }
    
    func wipe() {
        lock.lock()
        defer { lock.unlock() }
        _handle = nil
        stateSubject.send(.zero)
    }
}

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
            
            // Trigger initial sync
            do {
                let snapshot = try handle.refreshNow()
                let balance = try handle.confirmedBalanceAtomic()
                
                WalletHandleManager.shared.updateState(SynchronizerState(
                    syncStatus: .upToDate,
                    confirmedBalance: balance,
                    latestBlockHeight: BlockHeight(snapshot.chainTip)
                ))
            } catch {
                WalletHandleManager.shared.updateState(SynchronizerState(
                    syncStatus: .error(error.localizedDescription),
                    confirmedBalance: 0,
                    latestBlockHeight: 0
                ))
            }
        },
        stop: {
            WalletHandleManager.shared.updateState(SynchronizerState(
                syncStatus: .stopped,
                confirmedBalance: WalletHandleManager.shared.latestState.confirmedBalance,
                latestBlockHeight: WalletHandleManager.shared.latestState.latestBlockHeight
            ))
        },
        getConfirmedBalance: {
            guard let handle = WalletHandleManager.shared.handle else { return 0 }
            return (try? handle.confirmedBalanceAtomic()) ?? 0
        },
        getUnifiedAddress: { account in
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
                DarkfiTransactionOverview(
                    rawId: record.txHash,
                    minedHeight: record.blockHeight > 0 ? BlockHeight(record.blockHeight) : nil,
                    timestampEpochSeconds: nil,  // Not available from record
                    totalAtomicValue: record.netValueAtomic,
                    fee: record.feeAtomic,
                    isSending: record.isSent,
                    status: record.status,
                    contractSummary: record.contractSummary,
                    recipientAddress: record.recipientAddress,
                    memo: try? handle.transactionPaymentMemo(txHash: record.txHash)
                )
            }
        },
        proposeTransfer: { _, recipient, amount, _ in
            guard let handle = WalletHandleManager.shared.handle else {
                throw DarkfiError(message: "Wallet not initialized")
            }
            
            guard case .address(let recipientAddr) = recipient else {
                throw DarkfiError(message: "Invalid recipient")
            }
            
            // Check balance before proposing
            let balance = try handle.confirmedBalanceAtomic()
            let fee = try handle.estimateTransferFee(
                recipientAddress: recipientAddr,
                amount: String(amount),
                tokenId: nil,
                paymentMemo: nil
            )
            
            guard balance >= amount + fee else {
                throw DarkfiError(message: "Insufficient balance. Available: \(balance), required: \(amount + fee) (amount + fee)")
            }
            
            return Proposal(estimatedFee: fee)
        },
        estimateFee: { address, amount in
            guard let handle = WalletHandleManager.shared.handle else {
                return 10_000  // Default fee estimate
            }
            return (try? handle.estimateTransferFee(
                recipientAddress: address.stringEncoded,
                amount: String(amount),
                tokenId: nil,
                paymentMemo: nil
            )) ?? 10_000
        },
        sendTransaction: { _, amount, recipient, memo in
            guard let handle = WalletHandleManager.shared.handle else {
                throw DarkfiError(message: "Wallet not initialized")
            }
            
            guard case .address(let recipientAddr) = recipient else {
                throw DarkfiError(message: "Invalid recipient")
            }
            
            // Build and broadcast — memo forwarded from send flow
            let memoText: String? = memo?.text
            let txBytes = try handle.buildTransfer(
                recipientAddress: recipientAddr,
                amount: String(amount),
                tokenId: nil,
                paymentMemo: memoText
            )
            let txHash = try handle.broadcastTransfer(
                txBytes: txBytes,
                paymentMemo: memoText,
                recipientAddress: recipientAddr
            )
            
            // Refresh balance after send
            let newBalance = (try? handle.confirmedBalanceAtomic()) ?? 0
            let snapshot = (try? handle.syncSnapshot()) ?? DrkSyncSnapshot(scannedBlocks: 0, chainTip: 0)
            
            WalletHandleManager.shared.updateState(SynchronizerState(
                syncStatus: .upToDate,
                confirmedBalance: newBalance,
                latestBlockHeight: BlockHeight(snapshot.chainTip)
            ))
            
            return DarkfiTransactionOverview(
                rawId: txHash,
                totalAtomicValue: amount,
                fee: (try? handle.estimateTransferFee(
                    recipientAddress: recipientAddr,
                    amount: String(amount),
                    tokenId: nil,
                    paymentMemo: nil
                )) ?? 10_000,
                isSending: true,
                status: "Broadcasted",
                contractSummary: "Money::TransferV1",
                recipientAddress: recipientAddr,
                memo: memo?.text
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
            guard let handle = WalletHandleManager.shared.handle else { return [] }
            let ffiDaos = (try? handle.listDaos()) ?? []
            return ffiDaos.map { d in
                DaoBrief(
                    name: d.name, bullaB58: d.bullaB58, govTokenId: d.govTokenId,
                    quorumDisplay: d.quorumDisplay, proposerLimitDisplay: d.proposerLimitDisplay,
                    approvalRatioPercent: d.approvalRatioPercent,
                    mintHeight: d.mintHeight > 0 ? d.mintHeight : nil,
                    canPropose: d.canPropose, canVote: d.canVote, canExec: d.canExec
                )
            }
        },
        listProposals: { daoName in
            guard let handle = WalletHandleManager.shared.handle else { return [] }
            let ffiProposals = (try? handle.listProposals(daoName: daoName)) ?? []
            return ffiProposals.map { p in
                ProposalBrief(
                    proposalBullaB58: p.proposalBullaB58, daoName: p.daoName,
                    daoBullaB58: p.daoBullaB58, authCallCount: Int(p.authCallCount),
                    durationBlockwindows: Int64(p.durationBlockwindows),
                    creationBlockwindow: Int64(p.creationBlockwindow),
                    mintHeight: p.mintHeight > 0 ? p.mintHeight : nil,
                    execHeight: p.execHeight > 0 ? p.execHeight : nil,
                    isExecuted: p.isExecuted, summaryLine: p.summaryLine
                )
            }
        },
        getProposal: { bullaB58 in
            guard let handle = WalletHandleManager.shared.handle else { return nil }
            guard let d = try? handle.getProposal(proposalBullaB58: bullaB58) else { return nil }
            let brief = ProposalBrief(
                proposalBullaB58: d.proposalBullaB58, daoName: d.daoName,
                daoBullaB58: d.daoBullaB58, authCallCount: Int(d.authCallCount),
                durationBlockwindows: Int64(d.durationBlockwindows),
                creationBlockwindow: Int64(d.creationBlockwindow),
                mintHeight: d.mintHeight > 0 ? d.mintHeight : nil,
                execHeight: d.execHeight > 0 ? d.execHeight : nil,
                isExecuted: d.isExecuted, summaryLine: d.summaryLine
            )
            return ProposalFull(
                brief: brief,
                proposeTxHash: d.proposeTxHash,
                execTxHash: d.execTxHash,
                hasPlaintextData: d.hasPlaintextData
            )
        },
        wipe: {
            WalletHandleManager.shared.wipe()
        },
        rewind: {
            guard let handle = WalletHandleManager.shared.handle else {
                return Fail(error: DarkfiError(message: "Wallet not initialized"))
                    .eraseToAnyPublisher()
            }
            
            return Future<Void, Error> { promise in
                do {
                    _ = try handle.refreshNow()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
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
