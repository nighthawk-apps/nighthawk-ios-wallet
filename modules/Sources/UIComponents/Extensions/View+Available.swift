//
//  View+ColorScheme.swift
//  stealth
//

import SwiftUI

public extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
    }
}
