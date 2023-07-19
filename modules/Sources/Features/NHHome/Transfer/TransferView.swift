//
//  TransferView.swift
//  secant
//
//  Created by Matthew watt on 5/5/23.
//

import ComposableArchitecture
import SwiftUI

struct TransferView: View {
    let store: Store<TransferReducer.State, TransferReducer.Action>
    
    var body: some View {
        WithViewStore(store) { _ in
            Text("Transfer view")
        }
        .applyNighthawkBackground()
    }
}
