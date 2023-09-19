//
//  AboutView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import SwiftUI

public struct AboutView: View {
    let store: StoreOf<About>
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Text("About view")
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<About>) {
        self.store = store
    }
}
