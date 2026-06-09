//
//  TransactionState.swift
//  stealth
//
//  Created by Lukáš Korba on 26.04.2022.
//

import Foundation
import Utils

/// Representation of the transaction on the SDK side, used as a bridge to the TCA wallet side. 
public struct TransactionState: Codable, Equatable, Identifiable {
    public enum Status: Codable, Equatable {
        case paid(success: Bool)
        case received
        case failed
        case sending
        case receiving
    }
    
    public var errorMessage: String?
    public var expiryHeight: BlockHeight?
    public var memos: [Memo]?
    public var minedHeight: BlockHeight?
    public var shielded = true
    public var tAddress: String?
    public var zAddress: String?
    
    public var fee: DrkAmount
    public var id: String
    public var status: Status
    public var timestamp: TimeInterval?
    public var zecAmount: DrkAmount
    
    public var address: String? { zAddress ?? tAddress }
    
    public var unarySymbol: String {
        switch status {
        case .paid, .sending:
            return "-"
        case .received, .receiving:
            return "+"
        case .failed:
            return ""
        }
    }
    
    public var date: Date? {
        guard let timestamp else { return nil }
        
        return Date(timeIntervalSince1970: timestamp)
    }
    
    public var isSending: Bool {
        switch status {
        case .paid, .sending:
            return true
        default:
            return false
        }
    }
    
    public func viewOnlineURL(for networkType: String) -> URL? {
        return URL(string: "https://darkfi.explorer/tx/\(id)")
    }
    
    public func viewRecipientOnlineURL(for networkType: String) -> URL? {
        if let address {
            return URL(string: "https://darkfi.explorer/address/\(address)")
        }
        
        return nil
    }
    
    public var textMemo: Memo? {
        guard let memos else { return nil }
        return memos.first
    }
    
    public init(
        errorMessage: String? = nil,
        expiryHeight: BlockHeight? = nil,
        memos: [Memo]? = nil,
        minedHeight: BlockHeight? = nil,
        shielded: Bool = true,
        zAddress: String? = nil,
        fee: DrkAmount,
        id: String,
        status: Status,
        timestamp: TimeInterval? = nil,
        zecAmount: DrkAmount
    ) {
        self.errorMessage = errorMessage
        self.expiryHeight = expiryHeight
        self.memos = memos
        self.minedHeight = minedHeight
        self.shielded = shielded
        self.zAddress = zAddress
        self.fee = fee
        self.id = id
        self.status = status
        self.timestamp = timestamp
        self.zecAmount = zecAmount
    }
    
    public func confirmationsWith(_ latestMinedHeight: BlockHeight?) -> BlockHeight {
        guard let minedHeight, let latestMinedHeight, minedHeight > 0, latestMinedHeight > 0 else {
            return 0
        }
        
        return latestMinedHeight - minedHeight
    }
}

// MARK: - Placeholders

extension TransactionState {
    public static func placeholder(
        amount: DrkAmount = .zero,
        fee: DrkAmount = .zero,
        shielded: Bool = true,
        status: Status = .received,
        timestamp: TimeInterval = 0.0,
        uuid: String = UUID().debugDescription
    ) -> TransactionState {
        .init(
            expiryHeight: 0,
            memos: nil,
            minedHeight: 0,
            shielded: shielded,
            zAddress: nil,
            fee: fee,
            id: uuid,
            status: status,
            timestamp: timestamp,
            zecAmount: status == .received ? amount : -amount
        )
    }
}

public struct TransactionStateMockHelper {
    public var date: TimeInterval
    public var amount: DrkAmount
    public var shielded = true
    public var status: TransactionState.Status = .received
    public var uuid = ""
    
    public init(
        date: TimeInterval,
        amount: DrkAmount,
        shielded: Bool = true,
        status: TransactionState.Status = .received,
        uuid: String = ""
    ) {
        self.date = date
        self.amount = amount
        self.shielded = shielded
        self.status = status
        self.uuid = uuid
    }
}

// MARK: - DarkfiTransactionOverview -> TransactionState conversion

extension TransactionState {
    /// Convert a DarkfiTransactionOverview (from the SDK layer) to a TransactionState (for the UI layer)
    public init(from overview: DarkfiTransactionOverview) {
        var memos: [Memo]?
        if let memoStr = overview.memo, !memoStr.isEmpty,
           let memoData = memoStr.data(using: .utf8) {
            memos = [Memo(data: memoData)]
        }
        
        self.init(
            memos: memos,
            minedHeight: overview.minedHeight,
            shielded: true, // DarkFi: all transactions are private
            fee: overview.fee,
            id: overview.rawId,
            status: overview.isSending ? .paid(success: true) : .received,
            timestamp: overview.timestampEpochSeconds,
            zecAmount: overview.isSending ? -overview.totalAtomicValue : overview.totalAtomicValue
        )
    }
}
