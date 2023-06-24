//
//  BackupView.swift
//  secant
//
//  Created by Matthew Watt on 5/16/23.
//

import ComposableArchitecture
import SwiftUI

struct BackupView: View {
    let store: Store<BackupReducer.State, BackupReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("Backup view")
        }
        .applyNighthawkBackground()
    }
}
