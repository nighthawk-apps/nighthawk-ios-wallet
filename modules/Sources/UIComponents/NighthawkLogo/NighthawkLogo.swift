//
//  NighthawkLogo.swift
//  stealth
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import SwiftUI

public struct NighthawkLogo: View {
    public enum Spacing: CGFloat {
        case normal = 20
        case compact = 16
    }

    /// Logo dimensions aligned with Android `NighthawkBrandingHeader` / `ic_nighthawk_logo`.
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
            Asset.Assets.Icons.Nighthawk.nighthawkSymbol
                .image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.rawValue, height: size.rawValue)
                .foregroundColor(.white)

            if showsTitle {
                Text(L10n.Nighthawk.Splash.title)
                    .title()
            }
        }
    }
}
