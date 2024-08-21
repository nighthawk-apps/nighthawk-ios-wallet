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
        VStack(spacing: 32) {
            Asset.Assets.Icons.Nighthawk.nighthawkSymbolPeach
                .image
                .resizable()
                .frame(width: 35, height: 35)
                .padding(.bottom, 22)
                .padding(.top, 44)
            
            Spacer()
            
            Text(L10n.Nighthawk.WalletCreated.title)
                .paragraphMedium()
            
            Text(L10n.Nighthawk.WalletCreated.backupImmediately)
                .paragraphBold(color: .white)
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
            .buttonStyle(.nighthawkPrimary(width: 180))
            
            Button(L10n.Nighthawk.WalletCreated.skip) {
                store.send(.skip)
            }
            .buttonStyle(.nighthawkSecondary(width: 180))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 64)
    }
}
