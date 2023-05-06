//
//  NHHomeView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import SwiftUI

struct NHHomeView: View {
    let store: Store<NHHomeReducer.State, NHHomeReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                TabView(selection: viewStore.binding(\.$destination)) {
                    WalletView(store: store.walletStore())
                        .tag(NHHomeReducer.State.Destination.wallet)
                    
                    TransferView(store: store.transferStore())
                        .tag(NHHomeReducer.State.Destination.transfer)
                    
                    NHSettingsView(store: store.settingsStore())
                        .tag(NHHomeReducer.State.Destination.settings)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                NHTabBar(destination: viewStore.binding(\.$destination))
            }
        }
        .applyNighthawkBackground()
    }
}
