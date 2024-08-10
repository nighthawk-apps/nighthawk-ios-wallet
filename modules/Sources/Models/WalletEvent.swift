//
//  WalletEvent.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 20.06.2022.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit
import Utils

// MARK: - Model

public struct WalletEvent: Codable, Equatable, Identifiable, Redactable {
    public let transaction: TransactionState
    public let id: String
    public let timestamp: TimeInterval?
    
    public init(transaction: TransactionState) {
        self.transaction = transaction
        self.id = transaction.id
        self.timestamp = transaction.timestamp
    }
}

public extension Array where Element == WalletEvent {
    func sortedEvents(with chainTip: BlockHeight) -> [WalletEvent] {
        sorted(by: { lhs, rhs in
            var lhsHeight = chainTip
            
            if let lhsMinedHeight = lhs.transaction.minedHeight {
                lhsHeight = lhsMinedHeight
            } else if let lhsExpiredHeight = lhs.transaction.expiryHeight, lhsExpiredHeight > 0 {
                lhsHeight = lhsExpiredHeight
            }
            
            var rhsHeight = chainTip
            if let rhsMinedHeight = rhs.transaction.minedHeight {
                rhsHeight = rhsMinedHeight
            } else if let rhsExpiredHeight = rhs.transaction.expiryHeight, rhsExpiredHeight > 0 {
                rhsHeight = rhsExpiredHeight
            }
            
            return lhsHeight > rhsHeight
        })
    }
}
