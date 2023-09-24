//
//  WalletView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import Addresses
import ComposableArchitecture
import Generated
import SwiftUI
import TransactionDetail
import UIComponents

@MainActor
public struct WalletView: View {
    let store: StoreOf<Wallet>
    let tokenName: String
    
    public init(store: StoreOf<Wallet>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                qrCodeButtons(with: viewStore)
                
                header(with: viewStore)
                
                if viewStore.transparentBalance.data.verified >= viewStore.autoShieldingThreshold &&
                    viewStore.balanceViewType == .transparent &&
                    viewStore.synchronizerStatusSnapshot.syncStatus.isSynced {
                    Button(L10n.Nighthawk.WalletTab.shieldNow) {
                        viewStore.send(.shieldNowTapped)
                    }
                    .buttonStyle(.nighthawkPrimary())
                    .padding(.top, 16)
                }
                
                Spacer()
                
                latestWalletEvents(with: viewStore)
            }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension WalletView {
    func qrCodeButtons(with viewStore: ViewStoreOf<Wallet>) -> some View {
        HStack {
            Button(action: { viewStore.send(.viewAddressesTapped) }) {
                Asset.Assets.Icons.Nighthawk.nhQrCode.image
                    .resizable()
                    .frame(width: 22, height: 22)
                    .aspectRatio(contentMode: .fit)
            }
            .padding([.top, .leading], 25)
            
            Spacer()
            
            Button(action: { viewStore.send(.scanPaymentRequestTapped) }) {
                Asset.Assets.Icons.Nighthawk.boxedQrCode.image
                    .resizable()
                    .frame(width: 22, height: 22)
                    .aspectRatio(contentMode: .fit)
            }
            .padding([.top, .trailing], 25)
        }
    }
    
    func header(with viewStore: ViewStoreOf<Wallet>) -> some View {
        Group {
            if viewStore.synchronizerStatusSnapshot.syncStatus.isSyncing || viewStore.isSyncingFailed {
                SyncStatusView(status: viewStore.synchronizerStatusSnapshot)
            } else if viewStore.synchronizerStatusSnapshot.syncStatus.isSynced {
                balanceTabsView(with: viewStore)
            }
        }
    }
    
    func balanceTabsView(with viewStore: ViewStoreOf<Wallet>) -> some View {
        VStack {
            tabs(with: viewStore)
            tabIndicators(with: viewStore)
        }
        .frame(maxHeight: 180)
        .padding(.top, 58)
    }
    
    func tabs(with viewStore: ViewStoreOf<Wallet>) -> some View {
        TabView(selection: viewStore.$balanceViewType) {
            BalanceView(
                balance: viewStore.totalBalance,
                type: .hidden,
                tokenName: tokenName,
                synchronizerState: viewStore.synchronizerState
            )
            .tag(BalanceView.ViewType.hidden)
            
            BalanceView(
                balance: viewStore.totalBalance,
                type: .total,
                tokenName: tokenName,
                synchronizerState: viewStore.synchronizerState
            )
            .tag(BalanceView.ViewType.total)
            .padding(.top, 32)
            
            BalanceView(
                balance: viewStore.shieldedBalance.data.total,
                type: .shielded,
                tokenName: tokenName,
                synchronizerState: viewStore.synchronizerState
            )
            .tag(BalanceView.ViewType.shielded)
            .padding(.top, 32)
            
            BalanceView(
                balance: viewStore.transparentBalance.data.total,
                type: .transparent,
                tokenName: tokenName,
                synchronizerState: viewStore.synchronizerState
            )
            .tag(BalanceView.ViewType.transparent)
            .padding(.top, 32)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    func tabIndicators(with viewStore: ViewStoreOf<Wallet>) -> some View {
        HStack {
            ForEach(BalanceView.ViewType.allCases, id: \.self) { viewType in
                Circle()
                    .strokeBorder(
                        strokeColor(
                            for: viewStore.balanceViewType,
                            isSelected: viewType == viewStore.balanceViewType
                        ),
                        lineWidth: 3
                    )
                    .background(
                        Circle()
                            .fill(
                                fillColor(
                                    for: viewStore.balanceViewType,
                                    isSelected: viewType == viewStore.balanceViewType
                                )
                            )
                            .frame(width: 10, height: 10)
                    )
                    .frame(width: 16, height: 16)
            }
        }
    }
    
    func fillColor(for viewType: BalanceView.ViewType, isSelected: Bool) -> Color {
        switch viewType {
        case .hidden:
            return .clear
        default:
            return isSelected ? .white : Asset.Colors.Nighthawk.peach.color.opacity(0.6)
        }
    }
    
    func strokeColor(for viewType: BalanceView.ViewType, isSelected: Bool) -> Color {
        switch viewType {
        case .hidden:
            return .clear
        default:
            return isSelected ? Asset.Colors.Nighthawk.parmaviolet.color : .clear
        }
    }
    
    func latestWalletEvents(with viewStore: ViewStoreOf<Wallet>) -> some View {
        Group {
            if viewStore.synchronizerStatusSnapshot.syncStatus.isSynced && !viewStore.walletEvents.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text(L10n.Nighthawk.WalletTab.recentActivity)
                            .paragraphMedium()
                        Spacer()
                    }
                    
                    ForEach(viewStore.walletEvents.prefix(2)) { walletEvent in
                        Button {
                            viewStore.send(.viewTransactionDetailTapped(walletEvent))
                        } label: {
                            TransactionRowView(
                                transaction: walletEvent.transaction,
                                showAmount: viewStore.balanceViewType != .hidden,
                                tokenName: tokenName
                            )
                        }
                        
                        Divider()
                            .frame(height: 2)
                            .overlay(Asset.Colors.Nighthawk.navy.color)
                    }
                    
                    Button(action: { viewStore.send(.viewTransactionHistoryTapped) }) {
                        HStack(alignment: .center) {
                            Text(L10n.Nighthawk.WalletTab.viewTransactionHistory)
                                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                            
                            Spacer()
                            
                            Asset.Assets.Icons.Nighthawk.chevronRight.image
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 25)
            }
        }
    }
}
