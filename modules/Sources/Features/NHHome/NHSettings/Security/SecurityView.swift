//
//  SecurityView.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import SwiftUI

struct SecurityView: View {
    var store: Store<SecurityReducer.State, SecurityReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("Security view")
        }
        .applyNighthawkBackground()
    }
}
