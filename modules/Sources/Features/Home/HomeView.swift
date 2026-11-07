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
import Receive
import SendFlow
import SwiftUI
import UIComponents

public struct HomeView: View {
    @Bindable var store: StoreOf<Home>

    public var body: some View {
        GeometryReader { proxy in
            // Width gate matches Android `NighthawkExpandedWidth` / fold rail.
            let useRail = proxy.size.width >= NighthawkLayout.expandedWidth
            Group {
                if useRail {
                    HStack(spacing: 0) {
                        NighthawkTabBar(
                            selectedTab: store.selectedTab,
                            onSelect: { store.send(.tabSelected($0)) },
                            disableSend: store.synchronizerFailed,
                            placement: .leadingRail
                        )
                        .frame(width: NighthawkLayout.navigationRailWidth)
                        .frame(maxHeight: .infinity)

                        tabContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                } else {
                    tabContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            NighthawkTabBar(
                                selectedTab: store.selectedTab,
                                onSelect: { store.send(.tabSelected($0)) },
                                disableSend: store.synchronizerFailed,
                                placement: .bottomBar
                            )
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                        }
                }
            }
        }
        .environment(\.nighthawkSuppressNestedBackground, true)
        .background {
            NighthawkScreenBackdrop()
                .ignoresSafeArea()
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
        .sheet(
            item: $store.scope(
                state: \.transfer.destination?.send,
                action: \.transfer.destination.send
            )
        ) { store in
            SendFlowView(store: store)
        }
        .sheet(
            item: $store.scope(
                state: \.transfer.destination?.receive,
                action: \.transfer.destination.receive
            )
        ) { store in
            ReceiveView(store: store)
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
        case .chat:
            ChatView(
                store: store.scope(
                    state: \.chat,
                    action: \.chat
                )
            )

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

        case .transfer:
            TransferView(
                store: store.scope(
                    state: \.transfer,
                    action: \.transfer
                )
            )

        case .daoHub:
            DaoHubView(
                store: store.scope(
                    state: \.daoHub,
                    action: \.daoHub
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
