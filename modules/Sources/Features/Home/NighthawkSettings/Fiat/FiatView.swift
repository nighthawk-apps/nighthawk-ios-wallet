//
//  FiatView.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import SwiftUI

public struct FiatView: View {
    let store: StoreOf<Fiat>
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            Text("Fiat view")
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<Fiat>) {
        self.store = store
    }
}
