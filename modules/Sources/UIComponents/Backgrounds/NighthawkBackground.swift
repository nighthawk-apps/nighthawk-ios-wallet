//
//  NighthawkBackground.swift
//  stealth
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import Models
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

/// Wallpaper scaled until it covers the screen, pinned at the top-left
/// so the NIGHTHAWK title stays in frame.
public struct CyberpunkBackdrop: View {
    public init() {}

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.02, green: 0.024, blue: 0.04)
            Image("cyberpunk-bg", bundle: .module)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
            Color.black.opacity(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

public struct NighthawkScreenBackdrop: View {
    @ObservedObject private var themes = NighthawkThemeController.shared

    public init() {}

    public var body: some View {
        if themes.theme.usesCyberpunkChrome {
            CyberpunkBackdrop()
        } else {
            Asset.Colors.Nighthawk.darkNavy.color
                .ignoresSafeArea(edges: [.top, .horizontal])
        }
    }
}

public struct NighthawkBackgroundModifier: ViewModifier {
    @Environment(\.nighthawkSuppressNestedBackground) private var suppressNestedBackground

    public func body(content: Content) -> some View {
        if suppressNestedBackground {
            content
        } else {
            ZStack {
                NighthawkScreenBackdrop()
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
