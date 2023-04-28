//
//  NHWalletCreatedView.swift
//  secant
//
//  Created by Two Point on 4/19/23.
//

import ComposableArchitecture
import SwiftUI

struct NHWalletCreatedView: View {
    let store: NHWalletCreatedStore
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                heading
                Spacer()
                actions(viewStore: viewStore)
            }
        }
        .applyNighthawkBackground()
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews
private extension NHWalletCreatedView {
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
    
    func actions(viewStore: ViewStoreOf<NHWalletCreatedReducer>) -> some View {
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

struct NHWalletCreatedView_Previews: PreviewProvider {
    static var previews: some View {
        NHWalletCreatedView(store: .placeholder)
    }
}
