//
//  ReviewView.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents
import ZcashLightClientKit

public struct ReviewView: View {
    @Bindable var store: StoreOf<Review>
    let tokenName: String
    
    public init(store: StoreOf<Review>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        ScrollView([.vertical]) {
            NighthawkHeading(title: L10n.Nighthawk.TransferTab.Review.title)
                .padding(.bottom, 44)

            transactionSummary

            TransactionDetailsTable(
                lineItems: store.transactionLineItems(with: tokenName)
            )
            
            Button(
                L10n.Nighthawk.TransferTab.Review.send,
                action: { store.send(.sendZcashTapped) }
            )
            .buttonStyle(.nighthawkPrimary())
            .padding(.bottom, 28)
        }
        .showNighthawkBackButton(action: { store.send(.backButtonTapped) })
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
}

// MARK: - Subviews
private extension ReviewView {
    var transactionSummary: some View {
        VStack {
            HStack(alignment: .center) {
                Group {
                    Text("\(store.zecAmount.decimalString())")
                        .foregroundColor(.white)
                    
                    Text(tokenName)
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                }
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 28))
            }
            
            if let (currency, price) = store.fiatConversion {
                Text(
                    L10n.Nighthawk.TransferTab.Send.around(
                        (price * store.zecAmount.decimalValue.doubleValue).currencyString,
                        currency.rawValue.uppercased()
                    )
                )
                .paragraphMedium()
            }
        }
    }
}

// MARK: - Transaction Line Items
private extension StoreOf<Review> {
    // TODO: Consider using ResultBuilder for this.
    func transactionLineItems(with tokenName: String) -> [TransactionLineItem] {
        var result: [TransactionLineItem] = []
        if let memoStr = self.memo?.data, !memoStr.isEmpty {
            result.append(
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.memo,
                    value: memoStr,
                    isMemo: true
                )
            )
        }
        
        result.append(
            contentsOf: [
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.recipient,
                    value: self.recipientIsTransparent
                        ? L10n.Nighthawk.TransactionDetails.recipientTransparent
                        : L10n.Nighthawk.TransactionDetails.recipientShielded,
                    showBorder: false
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.address,
                    value: self.recipient,
                    action: .button(
                        title: L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer,
                        action: {
                            self.send(.warnBeforeLeavingApp(self.viewRecipientOnlineURL))
                        }
                    )
                )
            ]
        )
        
        result.append(
            contentsOf: [
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.networkFee,
                    value: "\(self.fee.decimalString()) \(tokenName)"
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.totalAmount,
                    value: "\(self.total.decimalString()) \(tokenName)"
                )
            ]
        )
        
        return result
    }
    
    var viewRecipientOnlineURL: URL? {
        URL(string: "https://3xpl.com/zcash/address/\(self.recipient.data)")
    }
}
