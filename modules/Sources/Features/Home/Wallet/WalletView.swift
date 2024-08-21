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
import Utils
import ZcashLightClientKit

@MainActor
public struct WalletView: View {
    @Bindable var store: StoreOf<Wallet>
    let tokenName: String
    
    public init(store: StoreOf<Wallet>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        VStack {
            qrCodeButtons
            
            Spacer()
            
            balanceTabsView
            
            if store.transparentBalance >= .autoshieldingThreshold &&
                store.balanceViewType == .transparent &&
                store.synchronizerStatusSnapshot.syncStatus.isSynced {
                Button(L10n.Nighthawk.WalletTab.shieldNow) {
                    store.send(.shieldNowTapped)
                }
                .buttonStyle(.nighthawkPrimary())
                .padding(.top, 16)
            }
            
            Spacer()
            
            latestWalletEvents
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension WalletView {
    var qrCodeButtons: some View {
        HStack {
            Button(action: { store.send(.viewAddressesTapped) }) {
                Asset.Assets.Icons.Nighthawk.nhQrCode.image
                    .resizable()
                    .frame(width: 22, height: 22)
                    .aspectRatio(contentMode: .fit)
            }
            .padding([.top, .leading], 25)
            
            Spacer()
            
            if store.showScanButton {
                Button(action: { store.send(.scanPaymentRequestTapped) }) {
                    Asset.Assets.Icons.Nighthawk.boxedQrCode.image
                        .resizable()
                        .frame(width: 22, height: 22)
                        .aspectRatio(contentMode: .fit)
                }
                .padding([.top, .trailing], 25)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
    
    var balanceTabsView: some View {
        VStack {
            tabs
                .transaction { transaction in
                    transaction.animation = nil
                }
            tabIndicators
        }
        .frame(maxHeight: 180)
        .padding(.top, 58)
        .environment(\.layoutDirection, .leftToRight)
    }
    
    @ViewBuilder var tabs: some View {
        if store.isSyncingForFirstTime {
            SyncStatusView(status: store.synchronizerStatusSnapshot)
        } else {
            TabView(selection: $store.balanceViewType) {
                Group {
                    if store.synchronizerStatusSnapshot.syncStatus.isSyncing || store.isSyncingFailed || store.isSyncingStopped {
                        SyncStatusView(status: store.synchronizerStatusSnapshot)
                    } else {
                        BalanceView(
                            balance: store.totalBalance,
                            type: .hidden,
                            tokenName: tokenName,
                            synchronizerState: store.synchronizerState
                        )
                    }
                }
                .tag(BalanceView.ViewType.hidden)
                
                BalanceView(
                    balance: store.totalBalance,
                    type: .total,
                    tokenName: tokenName,
                    synchronizerState: store.synchronizerState
                )
                .tag(BalanceView.ViewType.total)
                .padding(.top, 32)
                
                BalanceView(
                    balance: store.shieldedBalance,
                    type: .shielded,
                    tokenName: tokenName,
                    synchronizerState: store.synchronizerState
                )
                .tag(BalanceView.ViewType.shielded)
                .padding(.top, 32)
                
                BalanceView(
                    balance: store.transparentBalance,
                    type: .transparent,
                    tokenName: tokenName,
                    synchronizerState: store.synchronizerState
                )
                .tag(BalanceView.ViewType.transparent)
                .padding(.top, 32)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    var tabIndicators: some View {
        HStack {
            ForEach(BalanceView.ViewType.allCases, id: \.self) { viewType in
                Circle()
                    .strokeBorder(
                        strokeColor(
                            for: store.balanceViewType,
                            isSelected: viewType == store.balanceViewType
                        ),
                        lineWidth: 3
                    )
                    .background(
                        Circle()
                            .fill(
                                fillColor(
                                    for: store.balanceViewType,
                                    isSelected: viewType == store.balanceViewType
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
    
    var latestWalletEvents: some View {
        Group {
            if !store.isSyncingForFirstTime && !store.walletEvents.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text(L10n.Nighthawk.WalletTab.recentActivity)
                            .paragraphMedium()
                        Spacer()
                    }
                    
                    ForEach(store.walletEvents.prefix(2)) { walletEvent in
                        Button {
                            store.send(.viewTransactionDetailTapped(walletEvent))
                        } label: {
                            TransactionRowView(
                                transaction: walletEvent.transaction,
                                showAmount: store.balanceViewType != .hidden,
                                tokenName: tokenName,
                                fiatConversion: store.fiatConversion
                            )
                        }
                        
                        Divider()
                            .frame(height: 2)
                            .overlay(Asset.Colors.Nighthawk.navy.color)
                    }
                    
                    Button(action: { store.send(.viewTransactionHistoryTapped) }) {
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
