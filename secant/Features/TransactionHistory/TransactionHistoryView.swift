//
//  TransactionHistoryView.swift
//  secant
//
//  Created by Matthew Watt on 5/18/23.
//

import ComposableArchitecture
import SwiftUI

struct TransactionHistoryView: View {
    let store: Store<TransactionHistoryReducer.State, TransactionHistoryReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("Transaction history")
        }
        .applyNighthawkBackground()
    }
}
