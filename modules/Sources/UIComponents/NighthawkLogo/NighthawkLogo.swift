//
//  NighthawkLogo.swift
//  stealth
//

import SwiftUI

/// Android `NighthawkBrandingHeader` is a no-op after removing in-app logo /
/// wordmark chrome. The Cyberpunk wallpaper already carries the NIGHTHAWK mark;
/// this view only reserves vertical clearance so content sits below that mark
/// (`wallpaper_wordmark_clearance` = 48dp on Android).
public struct NighthawkLogo: View {
    public enum Spacing: CGFloat {
        case normal = 20
        case compact = 16
    }

    /// Kept for call-site compatibility; size no longer draws a glyph.
    public enum Size: CGFloat {
        case standard = 35
        case splash = 40
        /// Home tab headers (wallet, transfer, settings).
        case tabHeader = 105
    }

    /// Android `R.dimen.wallpaper_wordmark_clearance`.
    public static let wordmarkClearance: CGFloat = 48

    let spacing: Spacing
    let size: Size
    let showsTitle: Bool

    public init(
        spacing: Spacing = .normal,
        size: Size = .standard,
        showsTitle: Bool = true
    ) {
        self.spacing = spacing
        self.size = size
        self.showsTitle = showsTitle
    }

    public var body: some View {
        Color.clear
            .frame(height: Self.wordmarkClearance)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}
