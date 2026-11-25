//
//  NighthawkAlert+TCA.swift
//
//
//  Created by Matthew Watt on 9/8/23.
//

import ComposableArchitecture
import SwiftUI

extension View {
    public func nighthawkAlert<State, Action, Content: View>(
        item: Binding<Store<State, Action>?>,
        @ViewBuilder content: @escaping (_ store: Store<State, Action>) -> Content
    ) -> some View {
        self.nighthawkAlert(unwrapping: item) { $childStore in
            content(childStore)
        }
    }
}
