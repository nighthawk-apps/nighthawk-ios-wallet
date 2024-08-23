//
//  TransactionHistoryView.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct TransactionHistoryView: View {
    @Bindable var store: StoreOf<TransactionHistory>
    
    public var body: some View {
        ScrollView([.vertical], showsIndicators: false) {
            LazyVStack {
                ForEach(store.walletEvents) { walletEvent in
                    Button(action: { store.send(.viewTransactionDetailTapped(walletEvent)) }) {
                        TransactionRowView(
                            transaction: walletEvent.transaction,
                            showAmount: true,
                            tokenName: store.tokenName,
                            fiatConversion: store.fiatConversion
                        )
                    }
                    
                    Divider()
                        .frame(height: 2)
                        .overlay(Asset.Colors.Nighthawk.navy.color)
                }
            }
        }
        .padding(.horizontal, 25)
        .onAppear { store.send(.onAppear) }
        .overlay(alignment: .top) {
            if store.synchronizerStatusSnapshot.syncStatus.isSyncing {
                IndeterminateProgress()
            }
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<TransactionHistory>) {
        self.store = store
    }
}
