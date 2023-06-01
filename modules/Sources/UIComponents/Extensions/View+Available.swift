//
//  View+ColorScheme.swift
//  secant
//
//  Created by Matthew Watt on 3/17/23.
//

import SwiftUI

public extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
    }
}
