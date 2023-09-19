//
//  FailedView.swift
//  
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct FailedView: View {
    let store: StoreOf<Failed>
    
    public init(store: StoreOf<Failed>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                NighthawkHeading(title: L10n.Nighthawk.TransferTab.Failed.title)
                    .padding(.bottom, 44)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button(
                        L10n.Nighthawk.TransferTab.Failed.tryAgain,
                        action: { viewStore.send(.tryAgainTapped) }
                    )
                    .buttonStyle(.nighthawkPrimary())
                    
                    Button(
                        L10n.Nighthawk.TransferTab.Failed.cancel,
                        action: { viewStore.send(.cancelTapped) }
                    )
                    .buttonStyle(.nighthawkSecondary())
                }
                .padding(.bottom, 28)
            }
            .showNighthawkBackButton { viewStore.send(.backButtonTapped) }
        }
        .applyNighthawkBackground()
    }
}
