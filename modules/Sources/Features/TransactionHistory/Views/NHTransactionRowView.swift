//
//  NHTransactionRowView.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import Generated
import Models
import SwiftUI
import ZcashLightClientKit

public struct NHTransactionRowView: View {
    let transaction: TransactionState
    let showAmount: Bool
    let tokenName: String
    
    public init(transaction: TransactionState, showAmount: Bool = false, tokenName: String) {
        self.transaction = transaction
        self.showAmount = showAmount
        self.tokenName = tokenName
    }
    
    public var body: some View {
        HStack(alignment: .center) {
            icon
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(operationTitle)
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))

                Text("\(transaction.date?.asHumanReadable() ?? L10n.General.dateNotAvailable)")
                    .caption()
            }
            
            Spacer()
            
            Group {
                if showAmount {
                    Text(L10n.balance(transaction.zecAmount.decimalString(), tokenName))
                } else {
                    Text(L10n.balance("---", tokenName))
                }
            }
            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
        }
        .padding(.vertical)
    }
}

extension NHTransactionRowView {
    var operationTitle: String {
        switch transaction.status {
        case .paid:
            return L10n.Transaction.sent
        case .received:
            return L10n.Transaction.received
        case .failed:
            // TODO: [#392] final text to be provided (https://github.com/zcash/secant-ios-wallet/issues/392)
            return L10n.Transaction.failed
        case .sending:
            return L10n.Transaction.sending
        case .receiving:
            return L10n.Transaction.receiving
        }
    }
    
    var icon: Image {
        switch transaction.status {
        case .paid, .sending:
            return Asset.Assets.Icons.Nighthawk.sent.image
        case .received, .receiving:
            return Asset.Assets.Icons.Nighthawk.received.image
        case .failed:
            return Asset.Assets.Icons.Nighthawk.failed.image
        }
    }
}
