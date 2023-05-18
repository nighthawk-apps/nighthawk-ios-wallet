//
//  NotificationsView.swift
//  secant
//
//  Created by Matthew Watt on 5/14/23.
//

import ComposableArchitecture
import SwiftUI

struct NotificationsView: View {
    let store: Store<NotificationsReducer.State, NotificationsReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("Notifications view")
        }
        .applyNighthawkBackground()
    }
}
