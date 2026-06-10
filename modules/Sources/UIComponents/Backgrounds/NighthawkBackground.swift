//
//  NighthawkBackground.swift
//  stealth
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import SwiftUI

private struct NighthawkSuppressNestedBackgroundKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
  /// When true, `applyNighthawkBackground()` is skipped so nested home tab
  /// screens do not install full-screen backgrounds that block the tab bar.
    var nighthawkSuppressNestedBackground: Bool {
        get { self[NighthawkSuppressNestedBackgroundKey.self] }
        set { self[NighthawkSuppressNestedBackgroundKey.self] = newValue }
    }
}

public struct NighthawkBackgroundModifier: ViewModifier {
    @Environment(\.nighthawkSuppressNestedBackground) private var suppressNestedBackground
    
    public func body(content: Content) -> some View {
        if suppressNestedBackground {
            content
        } else {
            ZStack {
                Asset.Colors.Nighthawk.darkNavy.color
                    .ignoresSafeArea(edges: [.top, .horizontal])
                    .allowsHitTesting(false)
                content
            }
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
