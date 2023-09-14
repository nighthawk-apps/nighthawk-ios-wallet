//
//  ExternalServicesView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import SwiftUI

public struct ExternalServicesView: View {
    let store: StoreOf<ExternalServices>
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            Text("External services view")
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<ExternalServices>) {
        self.store = store
    }
}
