//
//  AutoshieldInProgressView.swift
//
//
//  Created by Matthew Watt on 9/21/23.
//

import Generated
import SwiftUI
import UIComponents
import Utils

public struct AutoshieldInProgressView: View {
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack(spacing: 22) {
                    NighthawkLogo(spacing: .compact)
                        .padding(.top, 44)
                    
                    Text(L10n.Nighthawk.Autoshield.shielding)
                        .subtitle(color: .white)
                    
                    Spacer()
                    
                    LottieAnimation(
                        isPlaying: true,
                        filename: "lottie_shielding",
                        animationType: .circularLoop
                    )
                    .frame(
                        width: geometry.size.width * 0.8,
                        height: geometry.size.width * 0.8
                    )
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .applyNighthawkBackground()
        .interactiveDismissDisabled()
    }
    
    public init() {}
}
