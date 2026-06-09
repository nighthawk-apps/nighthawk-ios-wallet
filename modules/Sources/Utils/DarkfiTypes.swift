//
//  DarkfiTypes.swift
//  stealth
//
//  DarkFi type definitions — matches Android nighthawk-dark SDK.
//  All wallet operations handled by Rust core via UniFFI.
//  DarkFi has ONLY privacy addresses. No tokenomics defined yet.
//

import Combine
import Foundation

// MARK: - Amount

/// Raw atomic balance value from the DarkFi Rust layer.
/// There is NO sub-unit name (no "zatoshi"). Balance is just Int64.
/// The Android SDK uses `Long` for `confirmedBalanceAtomic`.
public typealias DrkAmount = Int64

/// Display-scale for DRK amount formatting (matches Android `DarkfiAmountFormatter.DISPLAY_SCALE`).
public let DRK_DISPLAY_DECIMALS: Int = 8

extension DrkAmount {
    /// Human-readable string from atomic value (e.g. 100_000_000 → "1.0").
    public func formattedDrk(decimals: Int = DRK_DISPLAY_DECIMALS) -> String {
        let divisor = NSDecimalNumber(decimal: pow(10, decimals))
        let value = NSDecimalNumber(value: self).dividing(by: divisor)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(from: value) ?? "0"
    }

    /// Parse a user-entered decimal string into atomic DrkAmount.
    public static func fromDecimalString(_ string: String, decimals: Int = DRK_DISPLAY_DECIMALS) -> DrkAmount? {
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

// Backward-compatible typealiases — these will be collapsed during cleanup
public typealias UnifiedAddress = DarkfiAddress
public typealias TransparentAddress = DarkfiAddress
public typealias SaplingAddress = DarkfiAddress

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

    public static var zero: SynchronizerState {
        SynchronizerState(syncStatus: .disconnected, confirmedBalance: 0, latestBlockHeight: 0)
    }

    public init(
        syncStatus: DarkfiSyncStatus,
        confirmedBalance: DrkAmount = 0,
        latestBlockHeight: BlockHeight = 0
    ) {
        self.syncStatus = syncStatus
        self.confirmedBalance = confirmedBalance
        self.latestBlockHeight = latestBlockHeight
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

    public var id: String { rawId }

    public var date: Date? {
        guard let ts = timestampEpochSeconds else { return nil }
        return Date(timeIntervalSince1970: ts)
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
        memo: String? = nil
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
        return DarkfiError(message: localizedDescription)
    }
}

// MARK: - Recipient (privacy-only, no transparent/sapling)

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
