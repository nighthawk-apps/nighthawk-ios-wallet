//
//  DarkfiTypes.swift
//  stealth
//
//  DarkFi type definitions — matches Android nighthawk-dark SDK.
//  All wallet operations handled by Rust core via UniFFI.
//  DarkFi has ONLY privacy addresses. No tokenomics defined yet.
//

import Combine
import DarkfiCore
import Foundation

// MARK: - Amount

/// Raw atomic balance value from the DarkFi Rust layer.
/// There is NO sub-unit name (no "zatoshi"). Balance is just Int64.
/// The Android SDK uses `Long` for `confirmedBalanceAtomic`.
public typealias DrkAmount = Int64

/// Display-scale for DRK amount formatting (matches Android `DarkfiAmountFormatter.DISPLAY_SCALE`).
public let drkDisplayDecimals: Int = 8

extension DrkAmount {
    /// Human-readable string from atomic value (e.g. 100_000_000 → "1.0").
    public func formattedDrk(decimals: Int = drkDisplayDecimals) -> String {
        let divisor = NSDecimalNumber(decimal: pow(10, decimals))
        let value = NSDecimalNumber(value: self).dividing(by: divisor)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(from: value) ?? "0"
    }

    /// Parse a user-entered decimal string into atomic DrkAmount.
    public static func fromDecimalString(_ string: String, decimals: Int = drkDisplayDecimals) -> DrkAmount? {
        guard let decimal = Decimal(string: string) else { return nil }
        let atomic = decimal * pow(10, decimals)
        return NSDecimalNumber(decimal: atomic).int64Value
    }

    // MARK: - Backward-compatible methods (used by existing UI code)

    public var decimalValue: NSDecimalNumber {
        let decimal = Decimal(self) / Decimal(100_000_000)
        return NSDecimalNumber(decimal: decimal)
    }

    public func decimalString(formatter: NumberFormatter? = nil) -> String {
        formattedDrk()
    }

    /// Amount for a text field that `from(decimalString:)` reads back:
    /// "." decimal separator, no grouping, whatever the device locale.
    public func inputDecimalString(decimals: Int = drkDisplayDecimals) -> String {
        let divisor = NSDecimalNumber(decimal: pow(10, decimals))
        let value = NSDecimalNumber(value: self).dividing(by: divisor)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = 0
        return formatter.string(from: value) ?? "0"
    }

    public static func from(decimalString: String) -> DrkAmount? {
        fromDecimalString(decimalString)
    }
}

// MARK: - Block Height

public typealias BlockHeight = UInt32
public typealias CompactBlockRange = Range<BlockHeight>
public typealias RedactableBlockHeight = RedactableUInt32

public struct RedactableUInt32: Equatable, Redactable {
    public let data: UInt32
    public init(_ data: UInt32) { self.data = data }
}

extension UInt32 {
    public var redacted: RedactableUInt32 { RedactableUInt32(self) }
}

// MARK: - Address

/// DarkFi privacy address — the ONLY address type.
/// Generated and managed by the Rust `drk` plugin.
public struct DarkfiAddress: Equatable {
    public let stringEncoded: String
    public init(stringEncoded: String) { self.stringEncoded = stringEncoded }
}

// MARK: - Memo

public struct Memo: Equatable, Codable {
    public let data: Data
    public init(data: Data) { self.data = data }

    public init(string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw DarkfiError(message: "Failed to encode memo as UTF-8")
        }
        self.data = data
    }

    /// Text representation of the memo
    public var text: String? { String(data: data, encoding: .utf8) }

    public func toString() -> String? {
        String(data: data, encoding: .utf8)
    }

    public static var empty: Memo { Memo(data: Data()) }
}

// MARK: - Sync Status (matches Android DarkfiSyncStatus)

public enum DarkfiSyncStatus: Equatable {
    case unprepared      // Was: disconnected — maps to legacy "unprepared"
    case syncing(progress: Float)
    case upToDate        // Was: synced — maps to legacy "upToDate"
    case stopped
    case error(String)

    public var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }

    public var isSynced: Bool { self == .upToDate }
}

// Legacy compatibility alias
public typealias SyncStatus = DarkfiSyncStatus

// MARK: - Sync Method (mirrors Rust `SyncMethod` exported via UniFFI)

/// Retrieval / encryption path used to discover and sync notes.
///
/// This is the app-side mirror of the canonical Rust `SyncMethod` enum
/// (shared source of truth, exported to Swift + Kotlin via UniFFI). The SDK
/// layer maps `DarkfiCore.SyncMethod` into this type so the rest of the app
/// never depends on stringly-typed sync labels.
public enum DarkfiSyncMethod: String, Equatable, Codable, CaseIterable {
    /// True UnifOMR (ePrint 2026/910)
    case unifOmr
    /// Client-side trial decryption of compact blocks (fallback path).
    case trialDecrypt
    /// Idle, legacy, or not-yet-determined.
    case unknown

    /// Full display name for transaction detail / settings.
    public var displayName: String {
        switch self {
        case .unifOmr: return "UnifOMR"
        case .trialDecrypt: return "Trial decryption"
        case .unknown: return "Unknown"
        }
    }

    /// Compact label for the live home-screen indicator.
    public var shortLabel: String {
        switch self {
        case .unifOmr: return "UnifOMR"
        case .trialDecrypt: return "Trial"
        case .unknown: return "—"
        }
    }

    /// OMR-family methods provide oblivious (private) retrieval.
    public var isPrivateRetrieval: Bool {
        switch self {
        case .unifOmr: return true
        case .trialDecrypt, .unknown: return false
        }
    }
}

extension DarkfiSyncStatus {
    /// Alias: DarkFi uses "synced" / Android uses "synced"
    public static var synced: DarkfiSyncStatus { .upToDate }
    /// Alias: DarkFi uses "disconnected"
    public static var disconnected: DarkfiSyncStatus { .unprepared }
}

// MARK: - Synchronizer State (simplified — single balance)

public struct SynchronizerState: Equatable {
    public var syncStatus: DarkfiSyncStatus
    /// Single confirmed spendable balance in atomic DRK units (from Rust)
    public var confirmedBalance: DrkAmount
    public var latestBlockHeight: BlockHeight
    /// Canonical retrieval/encryption path currently in use (live sync method).
    public var activeSyncMethod: DarkfiSyncMethod
    /// Reason for fallback if activeSyncMethod is TrialDecrypt when UnifOMR was expected.
    public var fallbackReason: String
    /// User-facing message explaining the fallback. Empty when no fallback.
    public var fallbackUserMessage: String
    /// The Rust sync engine has a live lightwalletd session. `activeSyncMethod`
    /// sticks from the last good cycle, so it alone must not read as connected.
    public var lightwalletdConnected: Bool
    /// Human-readable status from Rust `DrkLightSyncState.status_message` (includes stale-tip warnings).
    public var lightStatusMessage: String?

    public static var zero: SynchronizerState {
        SynchronizerState(syncStatus: .disconnected, confirmedBalance: 0, latestBlockHeight: 0)
    }

    public init(
        syncStatus: DarkfiSyncStatus,
        confirmedBalance: DrkAmount = 0,
        latestBlockHeight: BlockHeight = 0,
        activeSyncMethod: DarkfiSyncMethod = .unknown,
        fallbackReason: String = "None",
        fallbackUserMessage: String = "",
        lightwalletdConnected: Bool = false,
        lightStatusMessage: String? = nil
    ) {
        self.syncStatus = syncStatus
        self.confirmedBalance = confirmedBalance
        self.latestBlockHeight = latestBlockHeight
        self.activeSyncMethod = activeSyncMethod
        self.fallbackReason = fallbackReason
        self.fallbackUserMessage = fallbackUserMessage
        self.lightwalletdConnected = lightwalletdConnected
        self.lightStatusMessage = lightStatusMessage
    }

    /// Map the Rust `LightSyncStatus` display string to a live-session flag.
    public static func lightwalletdLive(_ rustStatus: String) -> Bool {
        rustStatus == "Synced" || rustStatus == "Syncing" || rustStatus == "Scanning"
    }
}

// MARK: - Transaction Overview (matches Android DarkfiTransactionOverview)

public struct DarkfiTransactionOverview: Equatable, Identifiable {
    public let rawId: String
    public let minedHeight: BlockHeight?
    public let timestampEpochSeconds: TimeInterval?
    public let totalAtomicValue: DrkAmount
    public let fee: DrkAmount
    public let isSending: Bool
    public let status: String
    public let contractSummary: String
    public let recipientAddress: String?
    public let memo: String?
    /// How this transaction was discovered/built (from Rust `SyncMethod`).
    public let syncMethod: DarkfiSyncMethod

    public var id: String { rawId }

    public var date: Date? {
        guard let timestamp = timestampEpochSeconds else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    public init(
        rawId: String,
        minedHeight: BlockHeight? = nil,
        timestampEpochSeconds: TimeInterval? = nil,
        totalAtomicValue: DrkAmount,
        fee: DrkAmount = 0,
        isSending: Bool = false,
        status: String = "Confirmed",
        contractSummary: String = "Money::TransferV1",
        recipientAddress: String? = nil,
        memo: String? = nil,
        syncMethod: DarkfiSyncMethod = .unknown
    ) {
        self.rawId = rawId
        self.minedHeight = minedHeight
        self.timestampEpochSeconds = timestampEpochSeconds
        self.totalAtomicValue = totalAtomicValue
        self.fee = fee
        self.isSending = isSending
        self.status = status
        self.contractSummary = contractSummary
        self.recipientAddress = recipientAddress
        self.memo = memo
        self.syncMethod = syncMethod
    }
}

// MARK: - Seed Phrase (matches Android DarkfiSeedPhrase)

public enum DarkfiSeedPhrase {
    public static let wordCount: Int = 22
    public static let delimiter: String = " "
}

// MARK: - Wallet Init Mode

public enum WalletInitMode: Equatable {
    case newWallet
    case restoreWallet
    case existingWallet
}

// MARK: - Connection State

public enum ConnectionState: Equatable {
    case online
    case reconnecting
    case offline
}

// MARK: - DarkFi Network

public enum DarkfiNetwork: String {
    case mainnet
    case testnet

    public static let infoPlistKey = "DarkfiNetwork"

    /// Runtime network detection via host app `Info.plist` (`DarkfiNetwork`),
    /// with bundle identifier and display name fallbacks so SwiftPM modules
    /// resolve mainnet vs testnet reliably without `#if STEALTH_MAINNET`.
    public static func active(bundle: Bundle = .main) -> DarkfiNetwork {
        if let raw = bundle.object(forInfoDictionaryKey: infoPlistKey) as? String {
            let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let parsed = DarkfiNetwork(rawValue: normalized) {
                return parsed
            }
        }
        if let bundleId = bundle.bundleIdentifier?.lowercased() {
            if bundleId.contains("mainnet") {
                return .mainnet
            }
            if bundleId.contains("testnet") {
                return .testnet
            }
        }
        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            let lower = displayName.lowercased()
            if lower.contains("testnet") {
                return .testnet
            }
            if lower == "nighthawk" || lower.contains("mainnet") {
                return .mainnet
            }
        }
        return .testnet
    }

    public static var activeLabel: String {
        active().rawValue
    }
}

// MARK: - Error

public struct DarkfiError: Error, Equatable {
    public let message: String
    public init(message: String) {
        self.message = message
    }
}

// Legacy compatibility
public typealias DarkFiError = DarkfiError

extension Error {
    public func toDarkFiError() -> DarkfiError {
        if let e = self as? DarkfiError { return e }
        if let e = self as? DarkfiWalletNativeError {
            return DarkfiError(message: e.userFacingMessage)
        }
        return DarkfiError(message: localizedDescription)
    }
}

extension DarkfiWalletNativeError {
    /// Prefer the associated message over `String(reflecting:)`, so UI alerts
    /// surface bootstrap failures like sled lock / SQLCipher errors.
    var userFacingMessage: String {
        switch self {
        case let .WalletNotInitialized(message),
            let .InvalidBootstrapConfig(message),
            let .NativeDrkUnavailable(message),
            let .ConnectionFailed(message),
            let .SyncFailed(message),
            let .CryptoError(message),
            let .NetworkTimeout(message),
            let .ServerUnavailable(message),
            let .InvalidAddress(message),
            let .InsufficientFunds(message),
            let .TransactionBuildFailed(message),
            let .OmrDetectionFailed(message),
            let .TrialDecryptFailed(message):
            return message.isEmpty ? String(describing: self) : message
        }
    }
}

// MARK: - Recipient

public enum Recipient: Equatable {
    case address(String)
}

// MARK: - Transaction Proposal (stub for send flow)

/// Represents a transaction proposal with estimated fees.
/// In DarkFi, fees are computed by the Rust core.
public struct Proposal: Equatable {
    public let estimatedFee: DrkAmount

    public init(estimatedFee: DrkAmount = 10_000) {
        self.estimatedFee = estimatedFee
    }

    /// Legacy compatibility method
    public func totalFeeRequired() -> DrkAmount {
        estimatedFee
    }
}
