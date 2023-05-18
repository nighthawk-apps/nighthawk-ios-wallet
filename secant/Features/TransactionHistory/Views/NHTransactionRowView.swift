//
//  NHTransactionRowView.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import SwiftUI
import ZcashLightClientKit

struct NHTransactionRowView: View {
    var transaction: TransactionState
    var showAmount = false
    
    var body: some View {
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
                    Text(L10n.balance(transaction.zecAmount.decimalString(), TargetConstants.tokenName))
                } else {
                    Text(L10n.balance("---", TargetConstants.tokenName))
                }
            }
            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
        }
        .padding(.vertical)
    }
    
//    var body: some View {
//        ZStack {
//            icon
//
//            HStack {
//                VStack(alignment: .leading) {
//                    Text(operationTitle)
//                        .font(.system(size: 16))
//                        .foregroundColor(Asset.Colors.Mfp.fontDark.color)
//
//                    Text("\(transaction.date?.asHumanReadable() ?? L10n.General.dateNotAvailable)")
//                        .font(.system(size: 16))
//                        .foregroundColor(Asset.Colors.Mfp.fontDark.color)
//                        .opacity(0.5)
//                }
//
//                Spacer()
//
//                Group {
//                    Text(transaction.unarySymbol)
//                        .font(.system(size: 16))
//                        .foregroundColor(Asset.Colors.Mfp.fontDark.color)
//                    + Text(L10n.balance(transaction.zecAmount.decimalString(), TargetConstants.tokenName))
//                        .font(.system(size: 16))
//                        .foregroundColor(Asset.Colors.Mfp.fontDark.color)
//                }
//                .padding(.trailing, 30)
//            }
//            .padding(.leading, 80)
//
//            VStack {
//                Spacer()
//                Rectangle()
//                    .padding(.horizontal, 30)
//                    .frame(height: 1, alignment: .center)
//                    .foregroundColor(Asset.Colors.Text.transactionRowSubtitle.color)
//            }
//        }
//        .frame(height: 60)
//    }
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
        case .pending:
            return L10n.Transaction.sending
        }
    }
    
    var icon: Image {
        switch transaction.status {
        case .paid:
            return Asset.Assets.Icons.Nighthawk.sent.image
        case .received, .pending:
            return Asset.Assets.Icons.Nighthawk.received.image
        case .failed:
            return Asset.Assets.Icons.Nighthawk.failed.image
        }
    }
}
