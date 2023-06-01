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
    
    init(width: CGFloat? = nil) {
        self.width = width
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration, width: width)
    }
    
    struct PrimaryButton: View {
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
                        isEnabled ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.navy.color
                    ).opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .foregroundColor(isEnabled ? Asset.Colors.Nighthawk.darkNavy.color : Asset.Colors.Nighthawk.parmaviolet.color)
                .cornerRadius(4)
        }
    }
}

public extension ButtonStyle where Self == NighthawkPrimaryButtonStyle {
    static func nighthawkPrimary(width: CGFloat? = nil) -> NighthawkPrimaryButtonStyle { NighthawkPrimaryButtonStyle(width: width) }
}
