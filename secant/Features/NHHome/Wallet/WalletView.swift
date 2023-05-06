//
//  WalletView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import SwiftUI

struct WalletView: View {
    let store: Store<WalletReducer.State, WalletReducer.Action>
    
    var body: some View {
        WithViewStore(store) { _ in
            Text("Wallet view")
        }
        .applyNighthawkBackground()
    }
}
