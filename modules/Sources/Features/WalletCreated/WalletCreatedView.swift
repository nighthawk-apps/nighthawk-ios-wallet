//
//  WalletCreatedView.swift
//  stealth
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
            Asset.Assets.Icons.Nighthawk.nighthawkSymbol
                .image
                .renderingMode(.template)
                .resizable()
                .frame(width: 35, height: 35)
                .foregroundColor(.white)
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
            .buttonStyle(.nighthawkPrimary(width: 210))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 64)
    }
}
