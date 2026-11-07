//
//  SendingView.swift
//
//
//  Created by Matthew Watt on 8/1/23.
//

import Generated
import Models
import SwiftUI
import UIComponents
import Utils

public struct SendingView: View {
    @ObservedObject private var themes = NighthawkThemeController.shared

    public var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                    NighthawkHeading(title: L10n.Nighthawk.TransferTab.Sending.title)
                        .padding(.top, themes.theme.usesCyberpunkChrome ? NighthawkLayout.wallpaperWordmarkClearance : 0)
                        .padding(.bottom, 44)

                    LottieAnimation(
                        isPlaying: true,
                        filename: "lottie_sending",
                        animationType: .circularLoop
                    )
                    .frame(
                        width: geometry.size.width * 0.9
                    )
                    .aspectRatio(16 / 9, contentMode: .fit)

                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .applyNighthawkBackground()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .interactiveDismissDisabled()
    }

    public init() {}
}
