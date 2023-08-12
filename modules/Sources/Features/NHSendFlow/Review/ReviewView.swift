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
    let store: ReviewStore
    let tokenName: String
    
    public init(store: ReviewStore, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView([.vertical]) {
                NighthawkHeading(title: L10n.Nighthawk.TransferTab.Review.title)
                    .padding(.bottom, 44)

                transactionSummary(with: viewStore)

                TransactionDetailsTable(
                    lineItems: viewStore.transactionLineItems(with: tokenName)
                )
                
                Button(
                    L10n.Nighthawk.TransferTab.Review.send,
                    action: { viewStore.send(.sendZcashTapped) }
                )
                .buttonStyle(.nighthawkPrimary())
                .padding(.bottom, 28)
            }
            .showNighthawkBackButton(action: { viewStore.send(.backButtonTapped) })
        }
        .applyNighthawkBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
}

// MARK: - Subviews
private extension ReviewView {
    func transactionSummary(with viewStore: ReviewViewStore) -> some View {
        VStack {
            HStack(alignment: .center) {
                Group {
                    Text("\(viewStore.subtotal.decimalString())")
                        .foregroundColor(.white)
                    
                    Text(tokenName)
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                }
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 28))
            }
        }
    }
}

// MARK: - Transaction Line Items
private extension ReviewViewStore {
    // TODO: Consider using ResultBuilder for this.
    func transactionLineItems(with tokenName: String) -> [TransactionLineItem] {
        var result: [TransactionLineItem] = []
        if !self.memo.data.isEmpty {
            result.append(
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.memo,
                    value: self.memo.data,
                    isMemo: true
                )
            )
        }
        
        result.append(
            contentsOf: [
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.pool,
                    value: L10n.Nighthawk.TransactionDetails.sapling
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.recipient,
                    value: L10n.Nighthawk.TransactionDetails.recipientShielded,
                    showBorder: false
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.address,
                    value: self.recipient.data,
                    action: .init(
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
                    name: L10n.Nighthawk.TransactionDetails.subtotal,
                    value: "\(self.subtotal.decimalString()) \(tokenName)",
                    showBorder: false
                ),
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
        URL(string: "https://zcashblockexplorer.com/address/\(self.recipient.data)")
    }
}
