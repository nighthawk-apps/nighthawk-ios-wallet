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
            .overlay(alignment: .top) {
                syncProgressBanner
                    .padding(.top, 72)
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
    
    @ViewBuilder
    var syncProgressBanner: some View {
        let snapshot = store.walletInfo.synchronizerStatusSnapshot
        let blockHeight = store.walletInfo.synchronizerState.latestBlockHeight
        
        switch snapshot.syncStatus {
        case .upToDate:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
                Text("Synced · Block \(blockHeight)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            
        case let .syncing(progress):
            let percent = progress * 100
            HStack(spacing: 4) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
                    .tint(.white.opacity(0.7))
                Text(blockHeight > 0
                    ? String(format: "Syncing %.0f%% · Block %d", percent, blockHeight)
                    : String(format: "Syncing %.0f%%", percent))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            
        case .unprepared:
            HStack(spacing: 4) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
                    .tint(.white.opacity(0.7))
                Text("Connecting…")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            
        case .error:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Text("Sync Error")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            
        case .stopped:
            HStack(spacing: 4) {
                Image(systemName: "pause.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                Text("Sync Stopped")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
        }
    }
}
