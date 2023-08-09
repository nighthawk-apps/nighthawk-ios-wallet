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
    let store: Store<TransactionHistoryReducer.State, TransactionHistoryReducer.Action>
    let tokenName: String
    
    public init(
        store: Store<TransactionHistoryReducer.State, TransactionHistoryReducer.Action>,
        tokenName: String
    ) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView([.vertical], showsIndicators: false) {
                LazyVStack {
                    ForEach(viewStore.walletEvents) { event in
                        Button(action: {}) {
                            event.nhRowView(
                                showAmount: true,
                                tokenName: tokenName
                            )
                        }
                        
                        Divider()
                            .frame(height: 2)
                            .overlay(Asset.Colors.Nighthawk.navy.color)
                    }
                }
            }
            .padding(.horizontal, 25)
        }
        .applyNighthawkBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(L10n.Nighthawk.TransactionHistory.title)
                        .title()
                }
            }
        }
    }
}
