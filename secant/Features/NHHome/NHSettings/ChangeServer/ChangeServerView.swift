//
//  ChangeServerView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import SwiftUI

struct ChangeServerView: View {
    let store: Store<ChangeServerReducer.State, ChangeServerReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("Change server view")
        }
        .applyNighthawkBackground()
    }
}

