//
//  FiatView.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import SwiftUI

struct FiatView: View {
    let store: Store<FiatReducer.State, FiatReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("Fiat view")
        }
        .applyNighthawkBackground()
    }
}
