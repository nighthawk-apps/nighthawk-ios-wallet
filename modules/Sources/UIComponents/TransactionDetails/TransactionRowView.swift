//
//  TransactionRowView.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import Generated
import Models
import SwiftUI
import Utils
import ZcashLightClientKit

public struct TransactionRowView: View {
    let transaction: TransactionState
    let showAmount: Bool
    let tokenName: String
    let fiatConversion: (NighthawkSetting.FiatCurrency, Double)?
    
    public init(
        transaction: TransactionState,
        showAmount: Bool = false,
        tokenName: String,
        fiatConversion: (NighthawkSetting.FiatCurrency, Double)?
    ) {
        self.transaction = transaction
        self.showAmount = showAmount
        self.tokenName = tokenName
        self.fiatConversion = fiatConversion
    }
    
    public var body: some View {
        HStack(alignment: .center) {
            icon
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(operationTitle)
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    
                    if transaction.textMemo != nil {
                        Asset.Assets.Icons.Nighthawk.memo.image
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.white)
                    }
                }

                Text("\(transaction.date?.asHumanReadable() ?? "---")")
                    .caption()
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                if showAmount {
                    Text(L10n.balance(transaction.zecAmount.decimalString(), tokenName))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                        
                    if let (currency, price) = fiatConversion {
                        Text(
                            L10n.balance(
                                (price * transaction.zecAmount.decimalValue.doubleValue).currencyString,
                                currency.rawValue.uppercased()
                            )
                        )
                        .caption()
                    }
                } else {
                    Text(L10n.balance("---", tokenName))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    
                    if let (currency, _) = fiatConversion {
                        Text(L10n.balance("---", currency.rawValue.uppercased()))
                            .caption()
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

extension TransactionRowView {
    var operationTitle: String {
        switch transaction.status {
        case .paid:
            return L10n.Nighthawk.Transaction.sent
        case .received:
            return L10n.Nighthawk.Transaction.received
        case .failed:
            return L10n.Nighthawk.Transaction.failed
        case .sending:
            return L10n.Nighthawk.Transaction.sending
        case .receiving:
            return L10n.Nighthawk.Transaction.receiving
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
