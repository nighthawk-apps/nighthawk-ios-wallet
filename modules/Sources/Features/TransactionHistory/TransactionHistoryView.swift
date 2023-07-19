//
//  TransactionHistoryView.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import ComposableArchitecture
import SwiftUI

public struct TransactionHistoryView: View {
    let store: Store<TransactionHistoryReducer.State, TransactionHistoryReducer.Action>
    
    public init(store: Store<TransactionHistoryReducer.State, TransactionHistoryReducer.Action>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            Text("Transaction history")
        }
        .applyNighthawkBackground()
    }
}
