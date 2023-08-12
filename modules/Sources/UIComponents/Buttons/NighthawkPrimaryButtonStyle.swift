//
//  NighthawkPrimaryButtonStyle.swift
//  secant
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import SwiftUI

public struct NighthawkPrimaryButtonStyle: ButtonStyle {
    let width: CGFloat?
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(
        width: CGFloat? = nil,
        backgroundColor: Color,
        foregroundColor: Color
    ) {
        self.width = width
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(
            configuration: configuration,
            width: width,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )
    }
    
    struct PrimaryButton: View {
        let configuration: ButtonStyle.Configuration
        let width: CGFloat?
        let backgroundColor: Color
        let foregroundColor: Color
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
                        isEnabled ? backgroundColor : Asset.Colors.Nighthawk.navy.color
                    ).opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .foregroundColor(isEnabled ? foregroundColor : Asset.Colors.Nighthawk.parmaviolet.color)
                .cornerRadius(4)
        }
    }
}

public extension ButtonStyle where Self == NighthawkPrimaryButtonStyle {
    static func nighthawkPrimary(
        width: CGFloat? = nil,
        backgroundColor: Color = Asset.Colors.Nighthawk.peach.color,
        foregroundColor: Color = Asset.Colors.Nighthawk.darkNavy.color
    ) -> NighthawkPrimaryButtonStyle {
        NighthawkPrimaryButtonStyle(
            width: width,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )
    }
}
