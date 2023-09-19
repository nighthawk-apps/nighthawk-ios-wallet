//
//  WalletCreatedView.swift
//  secant
//
//  Created by Matthew Watt on 4/19/23.
//

import ComposableArchitecture
import Generated
import SubsonicClient
import SwiftUI
import UIComponents

public struct WalletCreatedView: View {
    let store: StoreOf<WalletCreated>
    
    public init(store: StoreOf<WalletCreated>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                NighthawkHeading(title: L10n.Nighthawk.WalletCreated.title)
                Spacer()
                actions(viewStore: viewStore)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension WalletCreatedView {
    func actions(viewStore: ViewStoreOf<WalletCreated>) -> some View {
        VStack(spacing: 16) {
            Button(L10n.Nighthawk.WalletCreated.backup) {
                viewStore.send(.backup)
            }
            .buttonStyle(.nighthawkPrimary(width: 180))
            
            Button(L10n.Nighthawk.WalletCreated.skip) {
                viewStore.send(.skip)
            }
            .buttonStyle(.nighthawkSecondary(width: 180))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 64)
    }
}
