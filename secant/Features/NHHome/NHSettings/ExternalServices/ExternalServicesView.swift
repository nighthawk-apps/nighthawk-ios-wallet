//
//  ExternalServicesView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import SwiftUI

struct ExternalServicesView: View {
    let store: Store<ExternalServicesReducer.State, ExternalServicesReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("External services view")
        }
        .applyNighthawkBackground()
    }
}
