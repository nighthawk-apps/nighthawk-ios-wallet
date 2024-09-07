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
    @Bindable var store: StoreOf<Home>
    
    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $store.selectedTab) {
                WalletView(
                    store: store.scope(
                        state: \.wallet,
                        action: \.wallet
                    )
                )
                .tag(Home.State.Tab.wallet)
                .overlay(alignment: .top) {
                    if store.walletInfo.synchronizerStatusSnapshot.syncStatus.isSyncing {
                        IndeterminateProgress()
                    }
                }
                
                TransferView(
                    store: store.scope(
                        state: \.transfer,
                        action: \.transfer
                    )
                )
                .tag(Home.State.Tab.transfer)
                
                NighthawkSettingsView(
                    store: store.scope(
                        state: \.settings,
                        action: \.settings
                    )
                )
                .tag(Home.State.Tab.settings)
            }
            .overlay(alignment: .top) {
                if store.selectedTab == .wallet {
                    NighthawkLogo(spacing: .compact)
                        .padding(.top, 40)
                }
            }
            
            NighthawkTabBar(
                destination: $store.selectedTab,
                disableSend: store.synchronizerFailed
            )
        }
        .onAppear { store.send(.onAppear) }
        .toast(
            unwrapping: $store.toast,
            case: /Home.State.Toast.expectingFunds,
            alert: {
                AlertToast(
                    type: .regular,
                    title: L10n.Nighthawk.HomeScreen.expectingFunds(
                        store.walletInfo.expectingZatoshi.decimalString(),
                        store.tokenName
                    )
                )
            }
        )
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
        .sheet(
            item: $store.scope(
                state: \.destination?.addresses,
                action: \.destination.addresses
            )
        ) { store in
            AddressesView(store: store)
        }
        .sheet(
            item: $store.scope(
                state: \.destination?.autoshield,
                action: \.destination.autoshield
            )
        ) { store in
            AutoshieldView(store: store)
        }
    }
    
    public init(store: StoreOf<Home>) {
        self.store = store
    }
}
