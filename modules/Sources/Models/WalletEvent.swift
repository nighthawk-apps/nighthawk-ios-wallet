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
