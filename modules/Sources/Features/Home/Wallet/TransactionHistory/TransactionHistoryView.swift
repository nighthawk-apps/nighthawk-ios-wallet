//
//  TransactionHistoryView.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct TransactionHistoryView: View {
    let store: StoreOf<TransactionHistory>
    let tokenName: String
    
    public init(
        store: StoreOf<TransactionHistory>,
        tokenName: String
    ) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView([.vertical], showsIndicators: false) {
                LazyVStack {
                    ForEach(viewStore.walletEvents) { walletEvent in
                        Button(action: { viewStore.send(.viewTransactionDetailTapped(walletEvent)) }) {
                            TransactionRowView(transaction: walletEvent.transaction, showAmount: true, tokenName: tokenName)
                        }
                        
                        Divider()
                            .frame(height: 2)
                            .overlay(Asset.Colors.Nighthawk.navy.color)
                    }
                }
            }
            .padding(.horizontal, 25)
            .onAppear { viewStore.send(.onAppear) }
            .overlay(alignment: .top) {
                if viewStore.synchronizerStatusSnapshot.syncStatus.isSyncing {
                    IndeterminateProgress()
                }
            }
        }
        .applyNighthawkBackground()
    }
}
