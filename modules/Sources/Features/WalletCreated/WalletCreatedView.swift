//
//  NHWalletCreatedView.swift
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
    let store: WalletCreatedStore
    
    public init(store: WalletCreatedStore) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                heading
                Spacer()
                actions(viewStore: viewStore)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .applyNighthawkBackground()
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews
private extension WalletCreatedView {
    @ViewBuilder var heading: some View {
        Asset.Assets.Icons.Nighthawk.nighthawkSymbolPeach
            .image
            .resizable()
            .frame(width: 35, height: 35)
            .padding(.bottom, 30)
            .padding(.top, 44)
        
        Text(L10n.Nighthawk.WalletCreated.title)
            .title
    }
    
    func actions(viewStore: ViewStoreOf<WalletCreatedReducer>) -> some View {
        VStack(spacing: 16) {
            Button(L10n.Nighthawk.WalletCreated.backup) {
                viewStore.send(.backup)
            }
            .buttonStyle(.nighthawkPrimary(width: 152))
            
            Button(L10n.Nighthawk.WalletCreated.skip) {
                viewStore.send(.skip)
            }
            .buttonStyle(.nighthawkSecondary(width: 152))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 64)
    }
}

// MARK: - Previews

struct WalletCreatedView_Previews: PreviewProvider {
    static var previews: some View {
        WalletCreatedView(store: .placeholder)
    }
}
