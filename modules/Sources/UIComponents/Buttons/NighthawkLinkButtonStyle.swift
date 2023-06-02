//
//  NighthawkLinkButtonStyle.swift
//  secant
//
//  Created by Matthew Watt on 4/16/23.
//

import Generated
import SwiftUI

public struct NighthawkLinkButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        LinkButton(configuration: configuration)
    }
    
    struct LinkButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .font(.custom(FontFamily.Roboto.regular.name, size: 12))
                .foregroundColor(
                    (
                        isEnabled ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.parmaviolet.color
                    ).opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .cornerRadius(4)
        }
    }
}

public extension ButtonStyle where Self == NighthawkLinkButtonStyle {
    static func nighthawkLink() -> NighthawkLinkButtonStyle { NighthawkLinkButtonStyle() }
}

