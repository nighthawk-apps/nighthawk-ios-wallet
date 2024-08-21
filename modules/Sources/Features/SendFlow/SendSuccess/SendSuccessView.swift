//
//  SendSuccessView.swift
//
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents
import Utils

public struct SendSuccessView: View {
    let store: StoreOf<SendSuccess>
    
    public init(store: StoreOf<SendSuccess>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                    NighthawkHeading(title: L10n.Nighthawk.TransferTab.Success.title)
                    
                    Spacer()
                    
                    LottieAnimation(
                        isPlaying: true,
                        filename: "lottie_send_success",
                        animationType: .playOnce
                    )
                    .frame(
                        width: geometry.size.width * 0.8,
                        height: geometry.size.width * 0.8
                    )
                    
                    Spacer()
                                            
                    VStack(spacing: 20) {
                        Button(
                            L10n.Nighthawk.TransferTab.Success.done,
                            action: { store.send(.doneTapped) }
                        )
                        .buttonStyle(.nighthawkPrimary())
                        
                        Button(
                            L10n.Nighthawk.TransferTab.Success.moreDetails,
                            action: { store.send(.moreDetailsTapped) }
                        )
                        .buttonStyle(.nighthawkSecondary())
                    }
                    .padding(.bottom, 28)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyNighthawkBackground()
    }
}
