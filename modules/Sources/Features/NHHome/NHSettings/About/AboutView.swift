//
//  AboutView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import SwiftUI

struct AboutView: View {
    let store: Store<AboutReducer.State, AboutReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("About view")
        }
        .applyNighthawkBackground()
    }
}
