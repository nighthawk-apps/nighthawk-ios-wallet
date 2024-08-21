//
//  SendFailedView.swift
//
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct SendFailedView: View {
    let store: StoreOf<SendFailed>
    
    public init(store: StoreOf<SendFailed>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            NighthawkHeading(title: L10n.Nighthawk.TransferTab.Failed.title)
                .padding(.bottom, 44)
            
            Spacer()
            
            VStack(spacing: 20) {
                Button(
                    L10n.Nighthawk.TransferTab.Failed.tryAgain,
                    action: { store.send(.tryAgainTapped) }
                )
                .buttonStyle(.nighthawkPrimary())
                
                Button(
                    L10n.Nighthawk.TransferTab.Failed.cancel,
                    action: { store.send(.cancelTapped) }
                )
                .buttonStyle(.nighthawkSecondary())
            }
            .padding(.bottom, 28)
        }
        .showNighthawkBackButton { store.send(.backButtonTapped) }
        .applyNighthawkBackground()
    }
}
