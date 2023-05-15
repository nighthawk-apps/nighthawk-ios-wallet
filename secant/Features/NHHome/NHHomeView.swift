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
                        .modify {
                            if viewStore.isSyncing {
                                $0.overlay(alignment: .top) {
                                    IndeterminateProgress()
                                }
                            } else {
                                $0
                            }
                        }
                    
                    TransferView(store: store.transferStore())
                        .tag(NHHomeReducer.State.Destination.transfer)
                    
                    NHSettingsView(store: store.settingsStore())
                        .tag(NHHomeReducer.State.Destination.settings)
                }
                .overlay(alignment: .top) {
                    NighthawkLogo(spacing: .compact)
                        .padding(.top, 40)
                        .accessDebugMenuWithHiddenGesture {
                            viewStore.send(.debugMenuStartup)
                        }
                }
                
                NHTabBar(destination: viewStore.binding(\.$destination), isUpToDate: viewStore.isUpToDate)
            }
            .onAppear { viewStore.send(.onAppear) }
        }
        .applyNighthawkBackground()
    }
}
