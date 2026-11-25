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
import Models
import UserPreferencesStorage
import Utils
import WalletStorage

public enum WalletSyncPrivacy {
    public static let strictOmrKey = "nighthawk.strictOmrOnly"

    public static var strictOmrOnly: Bool {
        if UserDefaults.standard.object(forKey: strictOmrKey) == nil {
            return false
        }
        return UserDefaults.standard.bool(forKey: strictOmrKey)
    }

    public static func setStrictOmrOnly(_ strict: Bool) {
        UserDefaults.standard.set(strict, forKey: strictOmrKey)
        WalletHandleManager.shared.handle?.setStrictOmrOnly(strict: strict)
    }
}

// MARK: - Wallet Handle Manager

/// Singleton manager for the DarkFi wallet handle.
/// The handle is created once during wallet preparation and reused.
private final class WalletHandleManager: @unchecked Sendable {
    static let shared = WalletHandleManager()

    private let lock = NSLock()
    private var _handle: DarkfiWalletHandle?
    private let stateSubject = CurrentValueSubject<SynchronizerState, Never>(.zero)
    /// Polls Rust background-sync snapshots so UI balance/height update while synced.
    private var pollTimer: DispatchSourceTimer?
    private let pollQueue = DispatchQueue(label: "com.nighthawkapps.wallet.poll")

    var handle: DarkfiWalletHandle? {
        lock.lock()
        defer { lock.unlock() }
        return _handle
    }

    func startPolling() {
        lock.lock()
        defer { lock.unlock() }
        guard pollTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: pollQueue)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            self?.pollBackgroundSync()
        }
        pollTimer = timer
        timer.resume()
    }

    func stopPolling() {
        lock.lock()
        defer { lock.unlock() }
        pollTimer?.cancel()
        pollTimer = nil
    }

    static func deriveSyncStatus(light: DrkLightSyncState, fallback: SyncStatus) -> SyncStatus {
        let tip = UInt32(truncatingIfNeeded: max(0, light.chainTip))
        let scanned = UInt32(truncatingIfNeeded: max(0, light.scannedHeight))
        let connected = SynchronizerState.lightwalletdLive(light.status)
        if light.chainTip > 0, scanned < tip {
            let progress = Float(scanned) / Float(max(tip, 1))
            return .syncing(progress: progress)
        }
        if connected {
            return .upToDate
        }
        let lowerStatus = light.status.lowercased()
        if lowerStatus.contains("error") || lowerStatus.contains("fail") {
            return .error(light.statusMessage.isEmpty ? light.status : light.statusMessage)
        }
        return fallback == .upToDate ? .unprepared : fallback
    }

    static func normalizeTokenId(_ tokenId: String?, tokenBalances: [DrkTokenBalance]) -> String? {
        guard let raw = tokenId?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if raw.caseInsensitiveCompare("DRK") == .orderedSame ||
            raw == "241vANigf1Cy3ytjM1KHXiVECxgxdK4yApddL8KcLssb" {
            return nil
        }
        if let label = tokenBalances.first(where: { $0.tokenId == raw })?.displayLabel?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           label.caseInsensitiveCompare("DRK") == .orderedSame {
            return nil
        }
        return raw
    }

    private func pollBackgroundSync() {
        guard let handle = handle else { return }
        let light = handle.lightSyncSnapshot()
        let balance = (try? handle.confirmedBalanceAtomic()) ?? latestState.confirmedBalance
        let tip = UInt32(truncatingIfNeeded: max(0, light.chainTip))
        let connected = SynchronizerState.lightwalletdLive(light.status)
        let syncStatus = Self.deriveSyncStatus(light: light, fallback: latestState.syncStatus)
        let next = SynchronizerState(
            syncStatus: syncStatus,
            confirmedBalance: balance,
            latestBlockHeight: tip > 0 ? tip : latestState.latestBlockHeight,
            activeSyncMethod: DarkfiSyncMethod(light.syncMethod),
            fallbackReason: String(describing: light.fallbackReason),
            fallbackUserMessage: light.fallbackUserMessage,
            lightwalletdConnected: connected,
            lightStatusMessage: light.statusMessage
        )
        let prev = latestState
        guard next.confirmedBalance != prev.confirmedBalance
            || next.latestBlockHeight != prev.latestBlockHeight
            || next.syncStatus != prev.syncStatus
            || next.lightwalletdConnected != prev.lightwalletdConnected
            || next.activeSyncMethod != prev.activeSyncMethod
            || next.lightStatusMessage != prev.lightStatusMessage
            || next.fallbackReason != prev.fallbackReason
            || next.fallbackUserMessage != prev.fallbackUserMessage else {
            return
        }
        updateState(next)
    }

    var stateStream: AnyPublisher<SynchronizerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var latestState: SynchronizerState {
        stateSubject.value
    }

    /// Default lightwalletd gRPC endpoint (standalone fhe-omr on :9067).
    static let defaultDarkfidEndpoint = "tcp://127.0.0.1:9067"

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
        let storedEndpoint = UserPreferencesStorage.live.customLightwalletdServer
        var endpoint = (storedEndpoint?.isEmpty == false ? storedEndpoint : nil)
            ?? WalletHandleManager.defaultDarkfidEndpoint
        endpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        if !endpoint.contains("://") {
            let lowerPort = endpoint.split(separator: ":").last
            endpoint = lowerPort == "443" ? "https://\(endpoint)" : "tcp://\(endpoint)"
        }

        // Fail-closed TLS pin verification before opening any remote HTTPS/TLS endpoint.
        let resolvedTlsPin = LightwalletTlsPin.activePinDataOrNil()
        if LightwalletTlsPin.requiresPin(forEndpoint: endpoint) && resolvedTlsPin == nil {
            throw DarkfiWalletNativeError.InvalidBootstrapConfig(
                message: "TLS pin (LIGHTWALLET_TLS_PIN_SHA256) is required for remote HTTPS lightwalletd endpoints."
            )
        }

        // S7: when the wallet network is Nym or Tor, rewrite non-loopback
        // endpoints to socks5://proxy/dest (Android TorDarkfidEndpoint parity).
        // Arti SOCKS host/port come from TorNetwork preferences; Nym listens on
        // loopback.
        let walletNetwork = SessionPrivacyOverride.resolved(
            stored: UserPreferencesStorage.live.walletPrivacyNetwork
        )
        let torForWallet = walletNetwork == .tor
        let nymForWallet = walletNetwork == .nym
        let socksHost = UserPreferencesStorage.live.torSocksHost ?? TorDarkfidEndpoint.defaultSocksHost
        let socksPort = UInt16(UserPreferencesStorage.live.torSocksPort ?? "9050")
            ?? TorDarkfidEndpoint.defaultSocksPort
        let nymSocksPort = NighthawkSetting.PrivacyNetwork.nymSocksPort
        endpoint = TorDarkfidEndpoint.toConnectUrl(
            endpoint: endpoint,
            torEnabled: walletNetwork != .direct,
            socksHost: nymForWallet ? TorDarkfidEndpoint.defaultSocksHost : socksHost,
            socksPort: nymForWallet ? nymSocksPort : socksPort
        )

        // Runtime Info.plist-driven network detection (works reliably inside SwiftPM).
        let networkLabel = DarkfiNetwork.activeLabel

        let config = DrkBootstrapConfig(
            network: networkLabel,
            mnemonic: words,
            walletDbPath: walletDbPath,
            cachePath: cachePath,
            walletPass: DrkWalletPassStore.forMnemonic(words: words),
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
            lightwalletTlsPinSha256: resolvedTlsPin.map { [UInt8]($0) },
            useTor: torForWallet,
            torSocksPort: socksPort,
            useNym: nymForWallet,
            nymSocksPort: nymSocksPort,
            darkfidRpcUrl: nil, // LWD-only; never hardcode a darkfid testnet port
            strictOmrOnly: WalletSyncPrivacy.strictOmrOnly
        )

        do {
            _handle = try DarkfiWalletHandle(config: config)
        } catch let error as DarkfiWalletNativeError {
            // Stale sled flock after a crash / overlapping prepare: clear cache once and retry.
            // Also recover from pre-SQLCipher plaintext DBs / passphrase mismatches after native
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
        stopPolling()
        lock.lock()
        defer { lock.unlock() }
        BlockTimestampIndex.reset()
        _handle = nil
        stateSubject.send(.zero)
    }

    /// Drop the live handle and delete on-disk wallet + cache databases.
    /// Keeps Keychain seed / wallet_pass so the user can reopen and rescan.
    func nukeLocalDatabases() {
        stopPolling()
        lock.lock()
        defer { lock.unlock() }
        BlockTimestampIndex.reset()
        _handle = nil
        stateSubject.send(.zero)

        // swiftlint:disable:next force_unwrapping
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let paths = [
            docs.appendingPathComponent("darkfi_wallet.db").path,
            docs.appendingPathComponent("darkfi_cache").path,
            docs.appendingPathComponent("ios_wallet_address.txt").path
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
                totalAtomicValue: amount,
                fee: (try? handle.estimateTransferFee(
                    recipientAddress: recipientAddr,
                    amount: amountDecimal,
                    tokenId: effectiveTokenId,
                    paymentMemo: memoText
                )) ?? 5_000_000,
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
