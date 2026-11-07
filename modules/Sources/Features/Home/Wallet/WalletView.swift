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

    @Environment(\.nighthawkUsesCompanionPane) private var usesCompanionPane

    public var body: some View {
        NighthawkSplitContainer {
            walletColumn
        } secondary: {
            WalletCompanionPane(store: store)
        }
    }

    private var walletColumn: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Clears the overlaid QR / Scan stack (top inset matches trailing = 25).
                Color.clear.frame(height: 25 + 88)

                syncStatusDot
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                // Balance sits in the space under the status dot.
                balanceTabsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                walletActionRow
                    .padding(.horizontal, 25)
                    .padding(.bottom, 8)

                latestWalletEvents
            }

            // QR actions stay in the top inset.
            qrCodeButtons
                .zIndex(1)
        }
        .applyNighthawkBackground()
        .onAppear { store.send(.refreshPreferences) }
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
            return StealthTheme.Colors.statusSuccess
        case .syncing, .unprepared:
            return StealthTheme.Colors.statusWarning
        case .error:
            return StealthTheme.Colors.statusDanger
        case .stopped:
            return Asset.Colors.Nighthawk.parmaviolet.color
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
        // Receive QR stacked above Scan on the top-right (Scan stays in its prior slot).
        VStack(alignment: .trailing, spacing: 0) {
            Button(action: { store.send(.viewAddressesTapped) }) {
                Asset.Assets.Icons.Nighthawk.nhQrCode.image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .frame(width: 24, height: 24)
                    .scaledToFit()
                    .frame(width: 44, height: 44, alignment: .topTrailing)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L10n.Nighthawk.WalletTab.Addresses.unifiedAddress)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("nighthawk.wallet.viewAddresses")

            if store.showScanButton {
                Button(action: { store.send(.scanPaymentRequestTapped) }) {
                    Asset.Assets.Icons.Nighthawk.boxedQrCode.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                        .frame(width: 24, height: 24)
                        .scaledToFit()
                        .frame(width: 44, height: 44, alignment: .topTrailing)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(L10n.Nighthawk.TransferTab.Send.scanCode)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("nighthawk.wallet.scan")
            }
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
        // Standard screen margin — top matches trailing (Android screen_standard_margin).
        .padding(.top, 25)
        .padding(.trailing, 25)
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
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("nighthawk.wallet.balance.\(viewType == .hidden ? "hidden" : "total")")
            }
        }
    }

    func fillColor(for viewType: BalanceView.ViewType, isSelected: Bool) -> Color {
        isSelected ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.textMuted.color
    }

    func strokeColor(for viewType: BalanceView.ViewType, isSelected: Bool) -> Color {
        isSelected ? Asset.Colors.Nighthawk.parmaviolet.color : .clear
    }

    var walletActionRow: some View {
        // Money chips: same selected-chip language as Chat Channels / Direct,
        // but teal/cyan primary (money) — never chat magenta.
        HStack(spacing: 8) {
            walletMoneyChip(
                title: L10n.Nighthawk.WalletTab.actionRequest,
                enabled: true,
                action: { store.send(.requestMoneyTapped) }
            )
            walletMoneyChip(
                title: L10n.Nighthawk.WalletTab.actionReceive,
                enabled: true,
                action: { store.send(.receiveMoneyTapped) }
            )
            walletMoneyChip(
                title: L10n.Nighthawk.WalletTab.actionSend,
                enabled: !store.isSyncingFailed && !store.isSyncingStopped,
                action: { store.send(.sendMoneyTapped) }
            )
        }
    }

    func walletMoneyChip(
        title: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        // Match Android Chat FilterChip / Channels·Direct (~8pt), not capsule pills.
        let chipShape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        let teal = StealthTheme.Colors.primary
        return Button(action: action) {
            Text(title)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                .foregroundColor(
                    enabled
                        ? Asset.Colors.Nighthawk.textHeader.color
                        : Asset.Colors.Nighthawk.textHeader.color.opacity(0.45)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(
                    chipShape
                        .fill(teal.opacity(enabled ? 0.38 : 0.18))
                )
                .overlay(
                    chipShape
                        .strokeBorder(teal.opacity(enabled ? 0.55 : 0.28), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityAddTraits(.isButton)
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
                            if usesCompanionPane {
                                store.send(.transactionSelected(walletEvent))
                            } else {
                                store.send(.viewTransactionDetailTapped(walletEvent))
                            }
                        } label: {
                            TransactionRowView(
                                transaction: walletEvent.transaction,
                                showAmount: store.balanceViewType != .hidden,
                                tokenName: store.tokenName,
                                fiatConversion: store.fiatConversion
                            )
                        }
                        .background(
                            store.selectedTransactionID == walletEvent.id
                                ? Asset.Colors.Nighthawk.peach.color.opacity(0.12)
                                : Color.clear
                        )

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
                                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
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
