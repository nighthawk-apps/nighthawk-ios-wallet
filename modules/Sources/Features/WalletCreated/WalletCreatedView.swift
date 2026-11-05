//
//  WalletCreatedView.swift
//  stealth
//
//  Created by Matthew Watt on 4/19/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct WalletCreatedView: View {
    let store: StoreOf<WalletCreated>

    public init(store: StoreOf<WalletCreated>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(L10n.Nighthawk.WalletCreated.title)
                .paragraphMedium()
                .padding(.top, 16)

            Text(L10n.Nighthawk.WalletCreated.backupImmediately)
                .paragraphBold(color: Asset.Colors.Nighthawk.textHeader.color)
                .lineSpacing(6)
                .multilineTextAlignment(.center)

            Spacer()
            actions
        }
        .padding(.horizontal, 25)
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension WalletCreatedView {
    var actions: some View {
        VStack(spacing: 16) {
            Button(L10n.Nighthawk.WalletCreated.backup) {
                store.send(.backup)
            }
            .buttonStyle(.nighthawkPrimary(width: 210))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 64)
    }
}
