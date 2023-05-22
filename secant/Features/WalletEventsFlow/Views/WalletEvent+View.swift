//
//  WalletEvent+View.swift
//  secant
//
//  Created by Lukáš Korba on 30.05.2023.
//

import ComposableArchitecture
import Models
import Generated
import SwiftUI
import ZcashLightClientKit

// MARK: - Rows

extension WalletEvent {
    @ViewBuilder func rowView(_ viewStore: WalletEventsFlowViewStore) -> some View {
        switch state {
        case .transaction(let transaction):
            TransactionRowView(transaction: transaction)
        case .shielded(let zatoshi):
            // TODO: [#390] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/390
            Text(L10n.WalletEvent.Row.shielded(zatoshi.decimalString()))
                .padding(.leading, 30)
        case .walletImport:
            // TODO: [#391] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/391
            Text(L10n.WalletEvent.Row.import)
                .padding(.leading, 30)
        }
    }
    
    @ViewBuilder func nhRowView(showAmount: Bool) -> some View {
        switch state {
        case .send(let transaction),
            .pending(let transaction),
            .received(let transaction),
            .failed(let transaction):
            NHTransactionRowView(transaction: transaction, showAmount: showAmount)
        case .shielded(let zatoshi):
            // TODO: [#390] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/390
            Text(L10n.WalletEvent.Row.shielded(zatoshi.decimalString()))
                .padding(.leading, 30)
        case .walletImport:
            // TODO: [#391] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/391
            Text(L10n.WalletEvent.Row.import)
                .padding(.leading, 30)
        }
    }
}

// MARK: - Details

extension WalletEvent {
    @ViewBuilder func detailView(_ store: WalletEventsFlowStore) -> some View {
        switch state {
        case .transaction(let transaction):
            TransactionDetailView(transaction: transaction, store: store)
        case .shielded(let zatoshi):
            // TODO: [#390] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/390
            Text(L10n.WalletEvent.Detail.shielded(zatoshi.decimalString()))
        case .walletImport:
            // TODO: [#391] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/391
            Text(L10n.WalletEvent.Detail.import)
        }
    }
    
    @ViewBuilder func nhDetailView() -> some View {
        switch state {
        case .send(let transaction),
            .pending(let transaction),
            .received(let transaction),
            .failed(let transaction):
            NHTransactionDetailView(transaction: transaction)
        case .shielded(let zatoshi):
            // TODO: [#390] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/390
            Text(L10n.WalletEvent.Detail.shielded(zatoshi.decimalString()))
        case .walletImport:
            // TODO: [#391] implement design once shielding is supported
            // https://github.com/zcash/secant-ios-wallet/issues/391
            Text(L10n.WalletEvent.Detail.import)
        }
    }
}

// MARK: - Placeholders

private extension WalletEvent {
    static func randomWalletEventState() -> WalletEvent.WalletEventState {
        switch Int.random(in: 0..<3) {
        case 1: return .shielded(Zatoshi(234_000_000))
        case 2: return .walletImport(BlockHeight(1_629_724))
        default: return .transaction(.placeholder)
        }
    }
    
    static func mockedWalletEventState(atIndex: Int) -> WalletEvent.WalletEventState {
        switch atIndex % 5 {
        case 0: return .transaction(.statePlaceholder(.received))
        case 1: return .transaction(.statePlaceholder(.failed))
        case 2: return .transaction(.statePlaceholder(.sending))
        case 3: return .transaction(.statePlaceholder(.receiving))
        case 4: return .transaction(.placeholder)
        default: return .transaction(.placeholder)
        }
    }
}

extension IdentifiedArrayOf where Element == WalletEvent {
    static var placeholder: IdentifiedArrayOf<WalletEvent> {
        return .init(
            uniqueElements: (0..<30).map {
                WalletEvent(
                    id: String($0),
                    state: WalletEvent.mockedWalletEventState(atIndex: $0),
                    timestamp: 1234567
                )
            }
        )
    }
}