//
//  WalletView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import TransactionHistory

public struct WalletView: View {
    let store: Store<WalletReducer.State, WalletReducer.Action>
    let tokenName: String
    
    public init(store: Store<WalletReducer.State, WalletReducer.Action>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                qrCodeButton()
                
                header(with: viewStore)
                
                Spacer()
                
                latestWalletEvents(with: viewStore)
            }
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.transactionHistory),
                destination: {
                    TransactionHistoryView(store: store.transactionHistoryStore())
                }
            )
            .navigationLinkEmpty(isActive: viewStore.bindingForSelectedWalletEvent(viewStore.selectedWalletEvent)) {
                viewStore.selectedWalletEvent?.nhDetailView(
                    latestMinedHeight: viewStore.latestMinedHeight,
                    requiredTransactionConfirmations: viewStore.requiredTransactionConfirmations,
                    tokenName: tokenName
                )
            }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension WalletView {
    func qrCodeButton() -> some View {
        HStack {
            Button(action: {}) {
                Asset.Assets.Icons.Nighthawk.nhQrCode.image
                    .resizable()
                    .frame(width: 22, height: 22)
                    .aspectRatio(contentMode: .fit)
            }
            .padding([.top, .leading], 25)
            
            Spacer()
        }
    }
    
    func header(with viewStore: ViewStore<WalletReducer.State, WalletReducer.Action>) -> some View {
        Group {
            if viewStore.synchronizerStatusSnapshot.isSyncing || viewStore.isSyncingFailed {
                SyncStatusView(status: viewStore.synchronizerStatusSnapshot)
            } else if viewStore.synchronizerStatusSnapshot.isSynced {
                balanceTabsView(with: viewStore)
            }
        }
    }
    
    func balanceTabsView(with viewStore: ViewStore<WalletReducer.State, WalletReducer.Action>) -> some View {
        VStack {
            tabs(with: viewStore)
            tabIndicators(with: viewStore)
        }
        .frame(maxHeight: 180)
        .padding(.top, 58)
    }
    
    func tabs(with viewStore: ViewStore<WalletReducer.State, WalletReducer.Action>) -> some View {
        TabView(selection: viewStore.binding(\.$balanceViewType)) {
            BalanceView(
                balance: viewStore.totalBalance,
                type: .hidden,
                tokenName: tokenName
            )
            .tag(BalanceView.ViewType.hidden)
            
            BalanceView(
                balance: viewStore.totalBalance,
                type: .total,
                tokenName: tokenName
            )
            .tag(BalanceView.ViewType.total)
            .padding(.top, 32)
            
            BalanceView(
                balance: viewStore.shieldedBalance.data.total,
                type: .shielded,
                tokenName: tokenName
            )
            .tag(BalanceView.ViewType.shielded)
            .padding(.top, 32)
            
            BalanceView(
                balance: viewStore.transparentBalance.data.total,
                type: .transparent,
                tokenName: tokenName
            )
            .tag(BalanceView.ViewType.transparent)
            .padding(.top, 32)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    func tabIndicators(with viewStore: ViewStore<WalletReducer.State, WalletReducer.Action>) -> some View {
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
    
    func latestWalletEvents(
        with viewStore: ViewStore<WalletReducer.State, WalletReducer.Action>
    ) -> some View {
        Group {
            if viewStore.synchronizerStatusSnapshot.isSynced && !viewStore.walletEvents.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text(L10n.Nighthawk.WalletTab.recentActivity)
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                        Spacer()
                    }
                    
                    ForEach(viewStore.walletEvents.prefix(2)) { walletEvent in
                        Button(action: { viewStore.send(.updateDestination(.showWalletEvent(walletEvent))) }) {
                            walletEvent.nhRowView(
                                showAmount: viewStore.balanceViewType != .hidden,
                                tokenName: tokenName
                            )
                        }
                        
                        Divider()
                            .frame(height: 2)
                            .overlay(Asset.Colors.Nighthawk.navy.color)
                    }
                    
                    Button(action: { viewStore.send(.viewTransactionHistory) }) {
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
