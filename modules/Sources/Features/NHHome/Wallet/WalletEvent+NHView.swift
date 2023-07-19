//
//  WalletEvent+NHView.swift
//  
//
//  Created by Matthew Watt on 7/1/23.
//

import ComposableArchitecture
import Models
import Generated
import SwiftUI
import TransactionHistory
import WalletEventsFlow
import ZcashLightClientKit

// MARK: - Rows

extension WalletEvent {    
    @ViewBuilder public func nhRowView(showAmount: Bool, tokenName: String) -> some View {
        switch state {
        case .transaction(let transaction):
            NHTransactionRowView(transaction: transaction, showAmount: showAmount, tokenName: tokenName)

        case .shielded(let zatoshi):
            // TODO: [#390] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/390
            Text(L10n.WalletEvent.Row.shielded(zatoshi.decimalString()))
                .padding(.leading, 30)
        case .walletImport:
            // TODO: [#391] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/391
            Text(L10n.WalletEvent.Row.import)
                .padding(.leading, 30)
        }
    }
}

// MARK: - Details

extension WalletEvent {
    @ViewBuilder public func nhDetailView(
        latestMinedHeight: BlockHeight?,
        requiredTransactionConfirmations: Int,
        tokenName: String
    ) -> some View {
        switch state {
        case .transaction(let transaction):
            NHTransactionDetailView(
                latestMinedHeight: latestMinedHeight,
                requiredTransactionConfirmations: requiredTransactionConfirmations,
                tokenName: tokenName,
                transaction: transaction
            )
        case .shielded(let zatoshi):
            // TODO: [#390] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/390
            Text(L10n.WalletEvent.Detail.shielded(zatoshi.decimalString()))
        case .walletImport:
            // TODO: [#391] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/391
            Text(L10n.WalletEvent.Detail.import)
        }
    }
}
