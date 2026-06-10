//
//  HomeView.swift
//  stealth
//
//  Created by Matthew Watt on 5/5/23.
//

import Addresses
import AlertToast
import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct HomeView: View {
    @Bindable var store: StoreOf<Home>
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .padding(.bottom, NighthawkTabBar.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .environment(\.nighthawkSuppressNestedBackground, true)
            
            NighthawkTabBar(
                selectedTab: store.selectedTab,
                onSelect: { store.send(.tabSelected($0)) },
                disableSend: store.synchronizerFailed
            )
            .zIndex(1)
        }
        .background {
            Asset.Colors.Nighthawk.darkNavy.color
                .ignoresSafeArea(edges: [.top, .horizontal])
                .allowsHitTesting(false)
        }
        .onAppear { store.send(.onAppear) }
        .toast(
            unwrapping: $store.toast,
            case: /Home.State.Toast.expectingFunds,
            alert: {
                AlertToast.nighthawkBanner(
                    type: .regular,
                    title: L10n.Nighthawk.HomeScreen.expectingFunds(
                        store.walletInfo.expectingAmount.decimalString(),
                        store.tokenName
                    )
                )
            }
        )
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
    }
    
    public init(store: StoreOf<Home>) {
        self.store = store
    }
}

// MARK: - Tab content
private extension HomeView {
    @ViewBuilder
    var tabContent: some View {
        switch store.selectedTab {
        case .wallet:
            WalletView(
                store: store.scope(
                    state: \.wallet,
                    action: \.wallet
                )
            )
            .overlay(alignment: .top) {
                if store.walletInfo.synchronizerStatusSnapshot.syncStatus.isSyncing {
                    IndeterminateProgress()
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .top) {
                NighthawkLogo(spacing: .compact, size: .tabHeader)
                    .padding(.top, 24)
                    .allowsHitTesting(false)
            }
            
        case .transfer:
            TransferView(
                store: store.scope(
                    state: \.transfer,
                    action: \.transfer
                )
            )
            
        case .chat:
            ChatView(
                store: store.scope(
                    state: \.chat,
                    action: \.chat
                )
            )
            
        case .settings:
            NighthawkSettingsView(
                store: store.scope(
                    state: \.settings,
                    action: \.settings
                )
            )
        }
    }
}
