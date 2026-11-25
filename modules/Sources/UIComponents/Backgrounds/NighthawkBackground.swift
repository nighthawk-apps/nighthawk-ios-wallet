//
//  NighthawkBackground.swift
//  stealth
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import Models
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
#if canImport(UIKit)
    /// Loose `.jpg` resources in an SPM bundle are not resolved by `Image(_:bundle:)`,
    /// so load and cache the wallpaper file directly.
    public static let wallpaperImage: UIImage? = {
        guard let url = Bundle.module.url(forResource: "cyberpunk-bg", withExtension: "jpg") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }()
#endif

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color(red: 0x05 / 255, green: 0x06 / 255, blue: 0x0A / 255)
                Self.wallpaperImageView
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                    .clipped()
                Color(red: 0x05 / 255, green: 0x08 / 255, blue: 0x10 / 255, opacity: 0.5)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

#if canImport(UIKit)
    @ViewBuilder
    private static var wallpaperImageView: some View {
        if let image = wallpaperImage {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
        }
    }
#else
    private static var wallpaperImageView: some View {
        Image("cyberpunk-bg", bundle: .module)
            .resizable()
            .interpolation(.high)
    }
#endif
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
