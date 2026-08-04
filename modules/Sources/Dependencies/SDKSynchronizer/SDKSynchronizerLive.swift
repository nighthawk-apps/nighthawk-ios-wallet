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
import UserPreferencesStorage
import Utils
import WalletStorage

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

    /// Default lightwalletd gRPC endpoint (Studio testnet via ngrok).
    static let defaultDarkfidEndpoint =
        "https://epidermis-sandbox-marshland.ngrok-free.dev"

    /// UserDefaults key for custom server endpoint (set by ChangeServer feature)
    static let serverEndpointKey = "darkfi_server_endpoint"

    func prepare(seed: [UInt8], birthday: BlockHeight, mode: WalletInitMode) throws {
        lock.lock()
        defer { lock.unlock() }

        // swiftlint:disable:next force_unwrapping
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let walletDbPath = docs.appendingPathComponent("darkfi_wallet.db").path
        let cachePath = docs.appendingPathComponent("darkfi_cache").path

        // Release any open sled/sqlite handles before wiping or reopening.
        // Leaving a live handle holds exclusive flock on `darkfi_cache/db` and
        // causes the next `Drk::new` to fail with NativeDrkUnavailable
        // ("could not acquire lock … Resource temporarily unavailable").
        _handle = nil

        // Only wipe on new wallet / restore — never on existingWallet reopen.
        switch mode {
        case .newWallet, .restoreWallet:
            try? FileManager.default.removeItem(atPath: walletDbPath)
            try? FileManager.default.removeItem(atPath: cachePath)
        case .existingWallet:
            break
        }

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

        // Read user-configured lightwalletd endpoint (from ChangeServer settings),
        // or fall back to standalone local lightwalletd.
        var storedEndpoint = UserPreferencesStorage.live.customLightwalletdServer
        var endpoint = (storedEndpoint?.isEmpty == false ? storedEndpoint : nil)
            ?? WalletHandleManager.defaultDarkfidEndpoint

        if !endpoint.contains("://") {
            endpoint = "tcp://\(endpoint)"
        }

        // S7: when Tor-for-wallet is on, rewrite non-loopback endpoints to
        // socks5://proxy/dest (Android TorDarkfidEndpoint parity). Arti SOCKS
        // host/port come from TorNetwork preferences.
        let torForWallet = UserPreferencesStorage.live.torForWalletEnabled
        let socksHost = UserPreferencesStorage.live.torSocksHost ?? TorDarkfidEndpoint.defaultSocksHost
        let socksPort = UInt16(UserPreferencesStorage.live.torSocksPort ?? "9050")
            ?? TorDarkfidEndpoint.defaultSocksPort
        endpoint = TorDarkfidEndpoint.toConnectUrl(
            endpoint: endpoint,
            torEnabled: torForWallet,
            socksHost: socksHost,
            socksPort: socksPort
        )

        // Scheme-driven network: stealth-mainnet vs stealth-testnet compilation flags.
        #if STEALTH_MAINNET
        let networkLabel = "mainnet"
        #else
        let networkLabel = "testnet"
        #endif

        let config = DrkBootstrapConfig(
            network: networkLabel,
            mnemonic: words,
            walletDbPath: walletDbPath,
            cachePath: cachePath,
            walletPass: DrkWalletPassStore.getOrCreate(),
            lightwalletServerUrl: endpoint,
            // Shared birthday contract with Android / desktop:
            //   0  = fresh create → seed scan cursor at LWD tip
            //  >0 = restore birthday (start near that height)
            //  -1 = unknown restore birthday → full history scan
            birthdayHeight: {
                switch mode {
                case .newWallet:
                    return 0
                case .restoreWallet:
                    return birthday == 0 ? -1 : Int64(birthday)
                case .existingWallet:
                    return Int64(birthday)
                }
            }(),
            lightwalletTlsPinSha256: LightwalletTlsPin.pinDataOrNil().map { [UInt8]($0) },
            useTor: torForWallet,
            torSocksPort: socksPort,
            darkfidRpcUrl: nil // LWD-only; never hardcode a darkfid testnet port
        )

        do {
            _handle = try DarkfiWalletHandle(config: config)
        } catch let error as DarkfiWalletNativeError {
            // Stale sled flock after a crash / overlapping prepare: clear cache once and retry.
            // Also recover from stale local DBs / passphrase mismatches after native
            // upgrades — keys are re-imported from the mnemonic on the next open.
            if case .NativeDrkUnavailable(let message) = error {
                let lower = message.lowercased()
                let sledLock =
                    lower.contains("could not acquire lock") ||
                    lower.contains("resource temporarily unavailable")
                let walletDb =
                    lower.contains("walletdb") ||
                    lower.contains("pragma") ||
                    lower.contains("file is not a database") ||
                    lower.contains("sqlite") ||
                    lower.contains("sqlcipher") ||
                    lower.contains("initializationfailed") ||
                    lower.contains("connectionfailed") ||
                    lower.contains("initialize_wallet") ||
                    lower.contains("databaseerror") ||
                    lower.contains("queryexecution")
                if sledLock || walletDb {
                    try? FileManager.default.removeItem(atPath: cachePath)
                    if walletDb {
                        try? FileManager.default.removeItem(atPath: walletDbPath)
                    }
                    try? FileManager.default.createDirectory(
                        atPath: cachePath,
                        withIntermediateDirectories: true
                    )
                    _handle = try DarkfiWalletHandle(config: config)
                } else {
                    throw error
                }
            } else {
                throw error
            }
        }

        // Surface chain reorgs to SynchronizerState (and any UI observing the stream).
        let manager = WalletHandleManager.shared
        _handle?.setReorgCallback(callback: ReorgCallbackBridge { event in
            var state = manager.latestState
            state.fallbackUserMessage = event.summaryMessage
            state.fallbackReason = "Reorg"
            manager.updateState(state)
        })

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

    /// Live retrieval/encryption path reported by the Rust sync engine.
    var activeSyncMethod: DarkfiSyncMethod {
        guard let handle = _handle else { return .unknown }
        return DarkfiSyncMethod(handle.lightSyncSnapshot().syncMethod)
    }

    func wipe() {
        lock.lock()
        defer { lock.unlock() }
        _handle = nil
        stateSubject.send(.zero)
    }

    /// Drop the live handle and delete on-disk wallet + cache databases.
    /// Keeps Keychain seed / wallet_pass so the user can reopen and rescan.
    func nukeLocalDatabases() {
        lock.lock()
        defer { lock.unlock() }
        _handle = nil
        stateSubject.send(.zero)

        // swiftlint:disable:next force_unwrapping
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let paths = [
            docs.appendingPathComponent("darkfi_wallet.db").path,
            docs.appendingPathComponent("darkfi_cache").path,
            docs.appendingPathComponent("ios_wallet_address.txt").path,
        ]
        for path in paths {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}

// MARK: - Sync method mapping (shared Rust model → app model)

private extension DarkfiSyncMethod {
    /// Map the UniFFI-exported `SyncMethod` (Rust source of truth) into the
    /// app-side enum so the UI never depends on the generated FFI type.
    init(_ core: SyncMethod) {
        switch core {
        case .unifOmr: self = .unifOmr
        case .trialDecrypt: self = .trialDecrypt
        case .unknown: self = .unknown
        }
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

                let lightState = handle.lightSyncSnapshot()

                WalletHandleManager.shared.updateState(SynchronizerState(
                    syncStatus: .upToDate,
                    confirmedBalance: balance,
                    latestBlockHeight: BlockHeight(snapshot.chainTip),
                    activeSyncMethod: DarkfiSyncMethod(lightState.syncMethod),
                    fallbackReason: String(describing: lightState.fallbackReason),
                    fallbackUserMessage: lightState.fallbackUserMessage
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
        isWalletPrepared: {
            WalletHandleManager.shared.handle != nil
        },
        refreshNow: {
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            let snapshot = try handle.refreshNow()
            let balance = (try? handle.confirmedBalanceAtomic()) ?? WalletHandleManager.shared.latestState.confirmedBalance
            let lightState = handle.lightSyncSnapshot()
            WalletHandleManager.shared.updateState(SynchronizerState(
                syncStatus: .upToDate,
                confirmedBalance: balance,
                latestBlockHeight: BlockHeight(snapshot.chainTip),
                activeSyncMethod: DarkfiSyncMethod(lightState.syncMethod),
                fallbackReason: String(describing: lightState.fallbackReason),
                fallbackUserMessage: lightState.fallbackUserMessage
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
            // Check balance before proposing
            let balance = try handle.confirmedBalanceAtomic()
            let fee = try handle.estimateTransferFee(
                recipientAddress: recipientAddr,
                amount: String(amount),
                tokenId: tokenId,
                paymentMemo: memoText
            )

            guard balance >= amount + fee else {
                throw DarkfiError(message: "Insufficient balance. Available: \(balance), required: \(amount + fee) (amount + fee)")
            }

            return Proposal(estimatedFee: fee)
        },
        estimateFee: { address, amount, tokenId in
            guard let handle = WalletHandleManager.shared.handle else {
                return 10_000  // Default fee estimate
            }
            return (try? handle.estimateTransferFee(
                recipientAddress: address.stringEncoded,
                amount: String(amount),
                tokenId: tokenId,
                paymentMemo: nil
            )) ?? 10_000
        },
        sendTransaction: { _, amount, recipient, memo, tokenId in
            guard let handle = WalletHandleManager.shared.handle else {
                throw DarkfiError(message: "Wallet not initialized")
            }

            guard case .address(let recipientAddr) = recipient else {
                throw DarkfiError(message: "Invalid recipient")
            }

            // Build and broadcast — PerfOMR/OMD clue embedded in Rust by default.
            let memoText: String? = memo?.text
            let txBytes = try handle.buildTransfer(
                recipientAddress: recipientAddr,
                amount: String(amount),
                tokenId: tokenId,
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
                latestBlockHeight: BlockHeight(snapshot.chainTip),
                activeSyncMethod: WalletHandleManager.shared.activeSyncMethod
            ))

            return DarkfiTransactionOverview(
                rawId: txHash,
                totalAtomicValue: amount,
                fee: (try? handle.estimateTransferFee(
                    recipientAddress: recipientAddr,
                    amount: String(amount),
                    tokenId: tokenId,
                    paymentMemo: memoText
                )) ?? 10_000,
                isSending: true,
                status: "Broadcasted",
                contractSummary: "Money::TransferV1",
                recipientAddress: recipientAddr,
                memo: memo?.text,
                // Outgoing tx carries the UnifOMR clue we embed by default.
                syncMethod: .unifOmr
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
                    name: d.name, bullaB58: d.bullaB58, govTokenId: d.govTokenId,
                    quorumDisplay: d.quorumDisplay, proposerLimitDisplay: d.proposerLimitDisplay,
                    approvalRatioPercent: d.approvalRatioPercent,
                    mintHeight: d.mintHeight > 0 ? d.mintHeight : nil,
                    canPropose: d.canPropose, canVote: d.canVote, canExec: d.canExec
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
            guard let handle = WalletHandleManager.shared.handle else {
                throw SDKSynchronizerError.walletNotPrepared
            }
            let d = try handle.getProposal(proposalBullaB58: bullaB58)
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

private enum SDKSynchronizerError: LocalizedError {
    case walletNotPrepared

    var errorDescription: String? {
        switch self {
        case .walletNotPrepared:
            return "Wallet not initialized. Connect to a DarkFi node under Settings → Change Server, then try again."
        }
    }
}

/// Bridges UniFFI `ReorgEventCallback` into the synchronizer state stream.
private final class ReorgCallbackBridge: ReorgEventCallback, @unchecked Sendable {
    private let handler: @Sendable (ReorgEvent) -> Void

    init(handler: @escaping @Sendable (ReorgEvent) -> Void) {
        self.handler = handler
    }

    func onReorg(event: ReorgEvent) {
        handler(event)
    }
}
