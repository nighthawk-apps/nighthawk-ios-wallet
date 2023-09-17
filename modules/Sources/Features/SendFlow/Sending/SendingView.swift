//
//  SendingView.swift
//  
//
//  Created by Matthew Watt on 8/1/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents
import Utils

public struct SendingView: View {
    let store: StoreOf<Sending>
    
    public init(store: StoreOf<Sending>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                    NighthawkHeading(title: L10n.Nighthawk.TransferTab.Sending.title)
                        .padding(.bottom, 44)
                    
                    LottieAnimation(
                        isPlaying: true,
                        filename: "lottie_sending",
                        animationType: .circularLoop
                    )
                    .frame(
                        width: geometry.size.width * 0.9
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .applyNighthawkBackground()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .interactiveDismissDisabled()
    }
}
