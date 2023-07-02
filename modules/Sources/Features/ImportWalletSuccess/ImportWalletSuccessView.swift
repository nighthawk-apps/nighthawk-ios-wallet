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
    let store: Store<ImportWalletSuccessReducer.State, ImportWalletSuccessReducer.Action>
    
    public init(store: Store<ImportWalletSuccessReducer.State, ImportWalletSuccessReducer.Action>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
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
                                viewStore.send(.viewWallet)
                            }
                            .buttonStyle(.nighthawkPrimary())
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .applyNighthawkBackground()
            .navigationBarHidden(true)
            .onAppear {
                viewStore.send(.generateSuccessFeedback)
            }
        }
    }
}
