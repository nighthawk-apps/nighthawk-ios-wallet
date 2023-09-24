//
//  NighthawkDashedButtonStyle.swift
//  
//
//  Created by Matthew Watt on 7/21/23.
//

import Generated
import SwiftUI

public struct NighthawkDashedButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        DashedButton(configuration: configuration)
            .foregroundColor(
                Asset.Colors.Nighthawk.peach.color.opacity(
                    configuration.isPressed ? 0.5 : 1.0
                )
            )
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(
                        Asset.Colors.Nighthawk.navy.color.opacity(
                            configuration.isPressed ? 0.5 : 1.0
                        )
                    )
            )
    }
    
    struct DashedButton: View {
        let configuration: ButtonStyle.Configuration
        var body: some View {
            configuration.label
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(configuration.isPressed ? 0.5 : 1.0))
                .frame(height: 38)
                .padding(.horizontal, 25)
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(
                            Asset.Colors.Nighthawk.peach.color.opacity(
                                configuration.isPressed ? 0.5 : 1.0
                            ),
                            style: StrokeStyle(lineWidth: 1, dash: [4])
                        )
                )
        }
    }
}

public extension ButtonStyle where Self == NighthawkDashedButtonStyle {
    static func nighthawkDashed() -> NighthawkDashedButtonStyle { NighthawkDashedButtonStyle() }
}
