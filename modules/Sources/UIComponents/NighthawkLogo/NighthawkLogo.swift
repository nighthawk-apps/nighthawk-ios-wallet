//
//  NighthawkLogo.swift
//  stealth
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import SwiftUI

/// Wordmark header for sub-screens (logo mark removed; title only).
public struct NighthawkLogo: View {
    public enum Spacing: CGFloat {
        case normal = 20
        case compact = 16
    }

    /// Retained for call-site compatibility with prior logo sizes.
    public enum Size: CGFloat {
        case standard = 35
        case splash = 40
        /// Home tab headers (wallet, transfer, settings).
        case tabHeader = 105
    }

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
        VStack(spacing: spacing.rawValue) {
            if showsTitle {
                Text(L10n.Nighthawk.Splash.title)
                    .title()
            }
        }
        // `size` kept for API compatibility after the logo mark was removed.
        .accessibilityIdentifier("nighthawk-wordmark-\(Int(size.rawValue))")
    }
}
