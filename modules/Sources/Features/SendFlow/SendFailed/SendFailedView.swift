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
            NighthawkHeading(title: L10n.Nighthawk.TransferTab.Failed.title, compact: true)
                .padding(.bottom, 24)

            if let errorMessage = store.errorMessage,
               !errorMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(errorMessage)
                    .paragraphMedium()
                    .foregroundColor(StealthTheme.Colors.statusDanger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)
            }

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
