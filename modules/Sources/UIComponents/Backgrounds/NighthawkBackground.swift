//
//  NighthawkBackground.swift
//  secant
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import SwiftUI

public struct NighthawkBackgroundModifier: ViewModifier {
    public func body(content: Content) -> some View {
        ZStack {
            Asset.Colors.Nighthawk.darkNavy.color
                .ignoresSafeArea()
            
            content
        }
    }
}

public extension View {
    /// Adds a Vertical Linear Gradient with the default Colors of VLinearGradient.
    /// Supports both Light and Dark Mode
    func applyNighthawkBackground() -> some View {
        self.modifier(NighthawkBackgroundModifier())
    }
}
