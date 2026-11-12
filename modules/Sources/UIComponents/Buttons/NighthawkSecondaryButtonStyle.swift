//
//  NighthawkSecondaryButtonStyle.swift
//  stealth
//

import Generated
import SwiftUI

public struct NighthawkSecondaryButtonStyle: ButtonStyle {
    let width: CGFloat?

    init(width: CGFloat? = nil) {
        self.width = width
    }

    public func makeBody(configuration: Configuration) -> some View {
        SecondaryButton(configuration: configuration, width: width)
    }

    struct SecondaryButton: View {
        let configuration: ButtonStyle.Configuration
        let width: CGFloat?
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .modify {
                    if let width {
                        $0.frame(width: width)
                    } else {
                        $0
                    }
                }
                .textCase(.uppercase)
                .font(.custom(FontFamily.Roboto.medium.name, size: 14))
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    (
                        isEnabled ? CyberpunkPalette.surface : Asset.Colors.Nighthawk.richBlack.color
                    ).opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .foregroundColor(
                    (
                        isEnabled ? CyberpunkPalette.primary : CyberpunkPalette.muted
                    ).opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .cornerRadius(8)
        }
    }
}

public extension ButtonStyle where Self == NighthawkSecondaryButtonStyle {
    static func nighthawkSecondary(width: CGFloat? = nil) -> NighthawkSecondaryButtonStyle { NighthawkSecondaryButtonStyle(width: width) }
}

/// Android `TertiaryButton` on Cyberpunk: dark translucent fill, light label.
public struct NighthawkTertiaryButtonStyle: ButtonStyle {
    let width: CGFloat?

    public init(width: CGFloat? = nil) {
        self.width = width
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modify {
                if let width {
                    $0.frame(width: width)
                } else {
                    $0
                }
            }
            .textCase(.uppercase)
            .font(.custom(FontFamily.Roboto.medium.name, size: 14))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(CyberpunkPalette.tertiaryFill.opacity(configuration.isPressed ? 0.5 : 1))
            .foregroundColor(CyberpunkPalette.body.opacity(configuration.isPressed ? 0.5 : 1))
            .cornerRadius(8)
    }
}

public extension ButtonStyle where Self == NighthawkTertiaryButtonStyle {
    static func nighthawkTertiary(width: CGFloat? = nil) -> NighthawkTertiaryButtonStyle {
        NighthawkTertiaryButtonStyle(width: width)
    }
}
