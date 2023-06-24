//
//  RescanView.swift
//  secant
//
//  Created by Matthew Watt on 5/16/23.
//

import ComposableArchitecture
import SwiftUI

struct RescanView: View {
    let store: Store<RescanReducer.State, RescanReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("Rescan view")
        }
        .applyNighthawkBackground()
    }
}
