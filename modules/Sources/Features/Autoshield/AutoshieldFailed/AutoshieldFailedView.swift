//
//  AutoshieldFailedView.swift
//
//
//  Created by Matthew Watt on 9/19/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents
import Utils

public struct AutoshieldFailedView: View {
    let store: StoreOf<AutoshieldFailed>
    
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack(spacing: 22) {
                    NighthawkLogo(spacing: .compact)
                        .padding(.top, 44)
                    
                    Text(L10n.Nighthawk.Autoshield.shieldingFailed)
                        .subtitle(color: .white)
                    
                    Spacer()
                    
                    LottieAnimation(
                        isPlaying: true,
                        filename: "lottie_auto_shield_failed",
                        animationType: .playOnce
                    )
                    .frame(
                        width: geometry.size.width * 0.8,
                        height: geometry.size.width * 0.8
                    )
                    
                    Spacer()
                    
                    Button(L10n.General.back) {
                        store.send(.backTapped)
                    }
                    .buttonStyle(.nighthawkPrimary(width: 120))
                    .padding(.bottom)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<AutoshieldFailed>) {
        self.store = store
    }
}
