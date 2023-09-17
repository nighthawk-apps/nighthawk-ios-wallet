//
//  ImportWalletSuccessView.swift
//  secant
//
//  Created by Matthew Watt on 5/13/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents
import Utils

public struct ImportWalletSuccessView: View {
    let store: StoreOf<ImportWalletSuccess>
    
    public init(store: StoreOf<ImportWalletSuccess>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                GeometryReader { geometry in
                    VStack(spacing: geometry.size.height * 0.2) {
                        LottieAnimation(
                            isPlaying: true,
                            filename: "lottie_success",
                            animationType: .playOnce
                        )
                        .frame(
                            width: geometry.size.width * 0.4,
                            height: geometry.size.width * 0.4
                        )
                                                
                        VStack(spacing: 16) {
                            Text(L10n.Nighthawk.ImportWalletSuccess.success)
                                .foregroundColor(.white)
                                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 24))
                            
                            Button(L10n.Nighthawk.ImportWalletSuccess.viewWallet) {
                                viewStore.send(.viewWalletTapped)
                            }
                            .buttonStyle(.nighthawkPrimary())
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .applyNighthawkBackground()
            .onAppear {
                viewStore.send(.generateSuccessFeedback)
            }
        }
    }
}
