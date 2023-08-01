//
//  ReviewView.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import Generated
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
            VStack {
                NighthawkHeading(title: L10n.Nighthawk.TransferTab.Review.title)
                
                Spacer()
            }
            .showNighthawkBackButton(action: { viewStore.send(.backButtonTapped) })
        }
        .applyNighthawkBackground()
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
                    value: "\(self.amount.decimalString()) \(tokenName)",
                    showBorder: false
                ),
                // TODO: calc fee
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.networkFee,
                    value: "\(Zatoshi.zero.decimalString()) \(tokenName)"
                ),
                // TODO: calc total based on subtotal and fees
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.totalAmount,
                    value: "\(self.amount.decimalString()) \(tokenName)"
                )
            ]
        )
        
        return result
    }
    
    var viewRecipientOnlineURL: URL? {
        URL(string: "https://zcashblockexplorer.com/address/\(self.recipient.data)")
    }
}
