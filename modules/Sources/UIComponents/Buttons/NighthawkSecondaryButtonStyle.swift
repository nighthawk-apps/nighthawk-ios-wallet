//
//  NighthawkSecondaryButtonStyle.swift
//  stealth
//
//  Created by Matthew Watt on 3/22/23.
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
                .font(.custom(FontFamily.Roboto.medium.name, size: 14, relativeTo: .subheadline))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(
                    (
                        isEnabled ? Asset.Colors.Nighthawk.navy.color : Asset.Colors.Nighthawk.richBlack.color
                    ).opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .foregroundColor(
                    (
                        isEnabled ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.parmaviolet.color
                    ).opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            Asset.Colors.Nighthawk.steelBorder.color.opacity(isEnabled ? 1.0 : 0.4),
                            lineWidth: 1
                        )
                )
        }
    }
}

public extension ButtonStyle where Self == NighthawkSecondaryButtonStyle {
    static func nighthawkSecondary(width: CGFloat? = nil) -> NighthawkSecondaryButtonStyle { NighthawkSecondaryButtonStyle(width: width) }
}
