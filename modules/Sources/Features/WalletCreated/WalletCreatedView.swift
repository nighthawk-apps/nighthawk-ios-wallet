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
                actions(viewStore: viewStore)
            }
            .padding(.horizontal, 25)
            .onAppear { viewStore.send(.onAppear) }
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
