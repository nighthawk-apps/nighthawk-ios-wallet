//
//  ChangeServerView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import SwiftUI

public struct ChangeServerView: View {
    let store: StoreOf<ChangeServer>
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Text("Change server view")
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<ChangeServer>) {
        self.store = store
    }
}

