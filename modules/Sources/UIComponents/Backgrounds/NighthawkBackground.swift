//
//  NighthawkBackground.swift
//  stealth
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import Models
import SwiftUI
import UIKit

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

/// Full wallpaper, one image pixel per screen pixel, anchored at the top left.
/// A taller or wider screen reveals more of the same picture. A dark veil keeps
/// DarkIRC, Wallet, Transfer, and Settings text readable.
public struct CyberpunkBackdrop: View {
    public init() {}

    public var body: some View {
        let scale = UIScreen.main.scale
        ZStack(alignment: .topLeading) {
            Color(red: 0.02, green: 0.024, blue: 0.04)
            Image("cyberpunk-bg", bundle: .module)
                .resizable()
                .interpolation(.high)
                .frame(width: 3840 / scale, height: 2160 / scale, alignment: .topLeading)
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
