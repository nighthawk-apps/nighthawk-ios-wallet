//
//  WalletEvent+NHView.swift
//  
//
//  Created by Matthew Watt on 7/1/23.
//

import ComposableArchitecture
import Generated
import Models
import TransactionDetail
import SwiftUI
import ZcashLightClientKit

// MARK: - Rows

extension WalletEvent {    
    @ViewBuilder public func nhRowView(showAmount: Bool, tokenName: String) -> some View {
        switch state {
        case .transaction(let transaction):
            TransactionRowView(transaction: transaction, showAmount: showAmount, tokenName: tokenName)

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
