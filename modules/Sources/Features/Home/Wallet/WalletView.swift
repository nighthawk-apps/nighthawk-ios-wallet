//
//  WalletView.swift
//  stealth
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

@MainActor
public struct WalletView: View {
    @Bindable var store: StoreOf<Wallet>
    @State private var balancePage: BalanceView.ViewType?

    public var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                NighthawkLogo(spacing: .compact, size: .tabHeader)
                    .padding(.top, 24)

                syncStatusDot
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                // Balance / swipe prompt centered between branding and recent activity
                // (same layout intent as Android WalletView).
                balanceTabsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                latestWalletEvents
            }

            // Overlay QR actions in the top inset so branding Y matches other tabs.
            qrCodeButtons
                .zIndex(1)
        }
        .applyNighthawkBackground()
    }

    public init(store: StoreOf<Wallet>) {
        self.store = store
    }
}

private extension WalletView {
    var syncStatusDot: some View {
        Circle()
            .fill(syncStatusColor)
            .frame(width: 14, height: 14)
            .accessibilityLabel(syncStatusAccessibilityLabel)
    }

    var syncStatusColor: Color {
        switch store.walletInfo.synchronizerStatusSnapshot.syncStatus {
        case .upToDate:
            return Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)
        case .syncing, .unprepared:
            return Color(red: 0xF9 / 255, green: 0xA8 / 255, blue: 0x25 / 255)
        case .error:
            return Color(red: 0xC6 / 255, green: 0x28 / 255, blue: 0x28 / 255)
        case .stopped:
            return Color(red: 0x9E / 255, green: 0x9E / 255, blue: 0x9E / 255)
        }
    }

    var syncStatusAccessibilityLabel: String {
        let blockHeight = store.walletInfo.synchronizerState.latestBlockHeight
        switch store.walletInfo.synchronizerStatusSnapshot.syncStatus {
        case .upToDate:
            return "Synced · Block \(blockHeight)"
        case let .syncing(progress):
            let percent = progress * 100
            return blockHeight > 0
                ? String(format: "Syncing %.0f%% · Block %d", percent, blockHeight)
                : String(format: "Syncing %.0f%%", percent)
        case .unprepared:
            return "Connecting…"
        case .error:
            return "Sync Error"
        case .stopped:
            return "Sync Stopped"
        }
    }

    var qrCodeButtons: some View {
        HStack {
            Button(action: { store.send(.viewAddressesTapped) }) {
                Asset.Assets.Icons.Nighthawk.nhQrCode.image
                    .resizable()
                    .frame(width: 22, height: 22)
                    .aspectRatio(contentMode: .fit)
                    .padding(12)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("nighthawk.wallet.viewAddresses")
            .padding(.top, 24)
            .padding(.leading, 13)

            Spacer()

            if store.showScanButton {
                Button(action: { store.send(.scanPaymentRequestTapped) }) {
                    Asset.Assets.Icons.Nighthawk.boxedQrCode.image
                        .resizable()
                        .frame(width: 22, height: 22)
                        .aspectRatio(contentMode: .fit)
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("nighthawk.wallet.scan")
                .padding(.top, 24)
                .padding(.trailing, 13)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    var balanceTabsView: some View {
        VStack {
            Spacer(minLength: 0)
            tabs
                .transaction { transaction in
                    transaction.animation = nil
                }
            tabIndicators
            Spacer(minLength: 0)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder var tabs: some View {
        if store.isSyncingForFirstTime {
            SyncStatusView(status: store.walletInfo.synchronizerStatusSnapshot)
        } else if store.walletInfo.synchronizerStatusSnapshot.syncStatus.isSyncing
                    || store.isSyncingFailed
                    || store.isSyncingStopped {
            SyncStatusView(status: store.walletInfo.synchronizerStatusSnapshot)
        } else {
            balancePager
        }
    }

    var balancePager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                balancePage(.hidden)
                    .containerRelativeFrame(.horizontal)
                    .id(BalanceView.ViewType.hidden)

                balancePage(.total)
                    .containerRelativeFrame(.horizontal)
                    .id(BalanceView.ViewType.total)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $balancePage)
        .frame(height: 150)
        .fixedSize(horizontal: false, vertical: true)
        .clipped()
        .contentShape(Rectangle())
        .onAppear {
            balancePage = store.balanceViewType
        }
        .onChange(of: balancePage) { _, newPage in
            guard let newPage, newPage != store.balanceViewType else { return }
            store.balanceViewType = newPage
        }
        .onChange(of: store.balanceViewType) { _, newType in
            guard balancePage != newType else { return }
            balancePage = newType
        }
    }

    func balancePage(_ viewType: BalanceView.ViewType) -> some View {
        BalanceView(
            balance: store.walletInfo.totalBalance,
            type: viewType,
            tokenName: store.tokenName,
            synchronizerState: store.walletInfo.synchronizerState
        )
        .padding(.top, viewType == .total ? 32 : 0)
    }

    var tabIndicators: some View {
        HStack {
            ForEach(BalanceView.ViewType.allCases, id: \.self) { viewType in
                Button {
                    store.balanceViewType = viewType
                } label: {
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
                .buttonStyle(.plain)
                .accessibilityIdentifier("nighthawk.wallet.balance.\(viewType == .hidden ? "hidden" : "total")")
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
            if !store.isSyncingForFirstTime && !store.walletInfo.walletEvents.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text(L10n.Nighthawk.WalletTab.recentActivity)
                            .paragraphMedium()
                        Spacer()
                    }

                    ForEach(store.walletInfo.walletEvents.prefix(2)) { walletEvent in
                        Button {
                            store.send(.viewTransactionDetailTapped(walletEvent))
                        } label: {
                            TransactionRowView(
                                transaction: walletEvent.transaction,
                                showAmount: store.balanceViewType != .hidden,
                                tokenName: store.tokenName,
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
