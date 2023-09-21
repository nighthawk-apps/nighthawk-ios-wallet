//
//  HomeView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import Addresses
import AlertToast
import Autoshield
import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct HomeView: View {
    let store: StoreOf<Home>
    let tokenName: String
    
    public init(store: StoreOf<Home>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                TabView(selection: viewStore.$selectedTab) {
                    WalletView(
                        store: store.scope(
                            state: \.wallet,
                            action: Home.Action.wallet
                        ),
                        tokenName: tokenName
                    )
                    .tag(Home.State.Tab.wallet)
                    .overlay(alignment: .top) {
                        if viewStore.synchronizerStatusSnapshot.isSyncing {
                            IndeterminateProgress()
                        }
                    }
                    
                    TransferView(
                        store: store.scope(
                            state: \.transfer,
                            action: Home.Action.transfer
                        ),
                        tokenName: tokenName
                    )
                    .tag(Home.State.Tab.transfer)
                    
                    NighthawkSettingsView(
                        store: store.scope(
                            state: \.settings,
                            action: Home.Action.settings
                        )
                    )
                    .tag(Home.State.Tab.settings)
                }
                .overlay(alignment: .top) {
                    if viewStore.selectedTab == .wallet {
                        NighthawkLogo(spacing: .compact)
                            .padding(.top, 40)
                    }
                }
                
                NighthawkTabBar(
                    destination: viewStore.$selectedTab,
                    isUpToDate: viewStore.synchronizerStatusSnapshot.isSynced
                )
            }
            .onAppear { viewStore.send(.onAppear) }
            .toast(
                unwrapping: viewStore.$toast,
                case: /Home.State.Toast.expectingFunds,
                alert: {
                    AlertToast(
                        type: .regular,
                        title: L10n.Nighthawk.HomeScreen.expectingFunds(
                            viewStore.expectingZatoshi.decimalString(),
                            tokenName
                        )
                    )
                }
            )
        }
        .applyNighthawkBackground()
        .sheet(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /Home.Destination.State.addresses,
            action: Home.Destination.Action.addresses
        ) { store in
            AddressesView(store: store)
        }
        .sheet(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /Home.Destination.State.autoshield,
            action: Home.Destination.Action.autoshield
        ) { store in
            AutoshieldView(store: store)
        }
    }
}
