//
//  NHSettingsView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import SwiftUI

struct NHSettingsView: View {
    let store: Store<NHSettingsReducer.State, NHSettingsReducer.Action>
    
    var body: some View {
        WithViewStore(store) { _ in
            Text("Settings view")
        }
        .applyNighthawkBackground()
    }
}
