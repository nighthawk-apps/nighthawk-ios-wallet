//
//  WalletHandleManager.swift
//  SDKSynchronizer
//
//  Thread-safe owner of the native DarkFi wallet handle and synchronizer state stream.
//

import Combine
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

/// Singleton manager for the DarkFi wallet handle.
/// The handle is created once during wallet preparation and reused.
final class WalletHandleManager: @unchecked Sendable {
    static let shared = WalletHandleManager()

    /// Default lightwalletd gRPC endpoint (standalone fhe-omr on :9067).
    static let defaultDarkfidEndpoint = "tcp://127.0.0.1:9067"
    /// UserDefaults key for custom server endpoint (set by ChangeServer feature).
    static let serverEndpointKey = "darkfi_server_endpoint"

    private let lock = NSLock()
    private let stateLock = NSLock()
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

    var stateStream: AnyPublisher<SynchronizerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var latestState: SynchronizerState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return stateSubject.value
    }

    /// Live retrieval/encryption path reported by the Rust sync engine.
    var activeSyncMethod: DarkfiSyncMethod {
        guard let handle = self.handle else { return .unknown }
        return DarkfiSyncMethod(handle.lightSyncSnapshot().syncMethod)
    }

    func updateState(_ state: SynchronizerState) {
        stateLock.lock()
        stateSubject.send(state)
        stateLock.unlock()
    }

    func mutateState(_ transform: (inout SynchronizerState) -> Void) {
        stateLock.lock()
        var next = stateSubject.value
        transform(&next)
        stateSubject.send(next)
        stateLock.unlock()
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

    func prepare(seed: [UInt8], birthday: BlockHeight, mode: WalletInitMode) throws {
        lock.lock()
        defer { lock.unlock() }

        let (walletDbPath, cachePath) = Self.prepareStoragePaths(mode: mode, releasing: &_handle)
        let words = try Self.parseMnemonicWords(from: seed)
        let conn = try Self.resolveConnectionConfig()

        let config = DrkBootstrapConfig(
            network: DarkfiNetwork.activeLabel,
            mnemonic: words,
            walletDbPath: walletDbPath,
            cachePath: cachePath,
            walletPass: DrkWalletPassStore.forMnemonic(words: words),
            lightwalletServerUrl: conn.endpoint,
            birthdayHeight: Self.resolvedBirthdayHeight(birthday: birthday, mode: mode),
            lightwalletTlsPinSha256: conn.resolvedTlsPin.map { [UInt8]($0) },
            useTor: conn.torForWallet,
            torSocksPort: conn.socksPort,
            useNym: conn.nymForWallet,
            nymSocksPort: conn.nymSocksPort,
            darkfidRpcUrl: nil,
            strictOmrOnly: WalletSyncPrivacy.strictOmrOnly
        )

        _handle = try Self.openHandleWithRecovery(
            config: config,
            walletDbPath: walletDbPath,
            cachePath: cachePath
        )

        // Surface chain reorgs to SynchronizerState (and any UI observing the stream).
        let manager = WalletHandleManager.shared
        _handle?.setReorgCallback(callback: ReorgCallbackBridge { event in
            manager.mutateState { state in
                state.fallbackUserMessage = event.summaryMessage
                state.fallbackReason = "Reorg"
            }
        })

        updateState(SynchronizerState(
            syncStatus: .unprepared,
            confirmedBalance: 0,
            latestBlockHeight: 0
        ))
    }

    func wipe() {
        stopPolling()
        lock.lock()
        defer { lock.unlock() }
        BlockTimestampIndex.reset()
        _handle = nil
        updateState(.zero)
    }

    /// Drop the live handle and delete on-disk wallet + cache databases.
    /// Keeps Keychain seed / wallet_pass so the user can reopen and rescan.
    func nukeLocalDatabases() {
        stopPolling()
        lock.lock()
        defer { lock.unlock() }
        BlockTimestampIndex.reset()
        _handle = nil
        updateState(.zero)

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

// MARK: - Sync Status & Bootstrap Helpers
extension WalletHandleManager {
    private struct ResolvedConnectionConfig {
        let endpoint: String
        let resolvedTlsPin: Data?
        let torForWallet: Bool
        let nymForWallet: Bool
        let socksPort: UInt16
        let nymSocksPort: UInt16
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
        let prev = latestState
        let balance = (try? handle.confirmedBalanceAtomic()) ?? prev.confirmedBalance
        let tip = UInt32(truncatingIfNeeded: max(0, light.chainTip))
        let connected = SynchronizerState.lightwalletdLive(light.status)
        let syncStatus = Self.deriveSyncStatus(light: light, fallback: prev.syncStatus)
        let next = SynchronizerState(
            syncStatus: syncStatus,
            confirmedBalance: balance,
            latestBlockHeight: tip > 0 ? tip : prev.latestBlockHeight,
            activeSyncMethod: DarkfiSyncMethod(light.syncMethod),
            fallbackReason: String(describing: light.fallbackReason),
            fallbackUserMessage: light.fallbackUserMessage,
            lightwalletdConnected: connected,
            lightStatusMessage: light.statusMessage
        )
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

    private static func prepareStoragePaths(
        mode: WalletInitMode,
        releasing handle: inout DarkfiWalletHandle?
    ) -> (walletDbPath: String, cachePath: String) {
        // swiftlint:disable:next force_unwrapping
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let walletDbPath = docs.appendingPathComponent("darkfi_wallet.db").path
        let cachePath = docs.appendingPathComponent("darkfi_cache").path

        // Release any open sled/sqlite handles before wiping or reopening.
        handle = nil

        switch mode {
        case .newWallet, .restoreWallet:
            try? FileManager.default.removeItem(atPath: walletDbPath)
            try? FileManager.default.removeItem(atPath: cachePath)
        case .existingWallet:
            break
        }
        try? FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true)
        return (walletDbPath, cachePath)
    }

    private static func parseMnemonicWords(from seed: [UInt8]) throws -> [String] {
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
        return words
    }

    private static func resolveConnectionConfig() throws -> ResolvedConnectionConfig {
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
        return ResolvedConnectionConfig(
            endpoint: endpoint,
            resolvedTlsPin: resolvedTlsPin,
            torForWallet: torForWallet,
            nymForWallet: nymForWallet,
            socksPort: socksPort,
            nymSocksPort: nymSocksPort
        )
    }

    private static func resolvedBirthdayHeight(birthday: BlockHeight, mode: WalletInitMode) -> Int64 {
        switch mode {
        case .newWallet:
            return 0
        case .restoreWallet:
            return birthday == 0 ? -1 : Int64(birthday)
        case .existingWallet:
            return Int64(birthday)
        }
    }

    private static func openHandleWithRecovery(
        config: DrkBootstrapConfig,
        walletDbPath: String,
        cachePath: String
    ) throws -> DarkfiWalletHandle {
        do {
            return try DarkfiWalletHandle(config: config)
        } catch let error as DarkfiWalletNativeError {
            guard case .NativeDrkUnavailable(let message) = error else {
                throw error
            }
            switch WalletDbRecovery.step(forNativeDrkMessage: message) {
            case .rethrow:
                throw error
            case .clearCacheOnly:
                WalletDbRecovery.replaceCacheDirectory(at: cachePath)
                return try DarkfiWalletHandle(config: config)
            case .quarantineWalletAndClearCache:
                try WalletDbRecovery.quarantineWalletDatabase(at: walletDbPath)
                WalletDbRecovery.replaceCacheDirectory(at: cachePath)
                return try DarkfiWalletHandle(config: config)
            }
        }
    }
}

/// Decides whether a `NativeDrkUnavailable` open error may discard local state.
/// Wallet bytes are renamed beside the original. They are not deleted.
enum WalletDbRecovery {
    enum Step: Equatable {
        case rethrow
        case clearCacheOnly
        case quarantineWalletAndClearCache
    }

    static func step(forNativeDrkMessage message: String) -> Step {
        let lower = message.lowercased()
        if isConfirmedWalletDatabaseDamage(lower) {
            return .quarantineWalletAndClearCache
        }
        if isSledCacheLock(lower) {
            return .clearCacheOnly
        }
        return .rethrow
    }

    /// Moves `path` to a sibling `*.quarantine-<uuid>` file when it exists.
    /// A missing file is left alone. A failed rename throws and does not delete the original.
    static func quarantineWalletDatabase(at path: String) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return
        }
        let source = URL(fileURLWithPath: path)
        let destination = uniqueQuarantineURL(for: source, fileManager: fileManager)
        try fileManager.moveItem(at: source, to: destination)
        for suffix in ["-wal", "-shm", "-journal"] {
            quarantineSidecar(
                at: "\(path)\(suffix)",
                preferredDestination: "\(destination.path)\(suffix)",
                fileManager: fileManager
            )
        }
    }

    static func replaceCacheDirectory(at cachePath: String) {
        try? FileManager.default.removeItem(atPath: cachePath)
        try? FileManager.default.createDirectory(
            atPath: cachePath,
            withIntermediateDirectories: true
        )
    }

    private static func isSledCacheLock(_ lower: String) -> Bool {
        lower.contains("could not acquire lock")
            || lower.contains("resource temporarily unavailable")
    }

    private static func isConfirmedWalletDatabaseDamage(_ lower: String) -> Bool {
        if isExcludedTransientOrCredential(lower) {
            return false
        }
        let markers = [
            "database disk image is malformed",
            "file is not a database",
            "malformed database",
            "database is locked",
            "database table is locked",
            "sqlite_corrupt",
            "sqlite_notadb",
            "sqlite_busy",
            "sqlite_locked"
        ]
        return markers.contains { lower.contains($0) }
    }

    private static func isExcludedTransientOrCredential(_ lower: String) -> Bool {
        let markers = [
            "disk i/o",
            "i/o error",
            "input/output error",
            "sqlite_ioerr",
            "database or disk is full",
            "disk is full",
            "sqlite_full",
            "no space left",
            "passphrase",
            "password",
            "wrong key",
            "hmac",
            "decrypt"
        ]
        return markers.contains { lower.contains($0) }
    }

    private static func uniqueQuarantineURL(for source: URL, fileManager: FileManager) -> URL {
        let directory = source.deletingLastPathComponent()
        let name = source.lastPathComponent
        var candidate = directory.appendingPathComponent("\(name).quarantine-\(UUID().uuidString)")
        var attempts = 0
        while fileManager.fileExists(atPath: candidate.path), attempts < 8 {
            attempts += 1
            candidate = directory.appendingPathComponent("\(name).quarantine-\(UUID().uuidString)")
        }
        return candidate
    }

    private static func quarantineSidecar(
        at path: String,
        preferredDestination: String,
        fileManager: FileManager
    ) {
        guard fileManager.fileExists(atPath: path) else { return }
        if (try? fileManager.moveItem(atPath: path, toPath: preferredDestination)) != nil {
            return
        }
        let fallback = "\(preferredDestination).\(UUID().uuidString)"
        try? fileManager.moveItem(atPath: path, toPath: fallback)
    }
}

// MARK: - Sync method mapping (shared Rust model → app model)
extension DarkfiSyncMethod {
    init(_ core: SyncMethod) {
        switch core {
        case .unifOmr: self = .unifOmr
        case .trialDecrypt: self = .trialDecrypt
        case .unknown: self = .unknown
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
