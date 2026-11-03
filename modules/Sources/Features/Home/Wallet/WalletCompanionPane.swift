//
//  WalletCompanionPane.swift
//
//  Right fold of the wallet split. Empty selection is the companion hub.
//  A selected transaction shows detail plus Next Steps.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents
import Utils

struct WalletCompanionPane: View {
    @Bindable var store: StoreOf<Wallet>

    var body: some View {
        ScrollView {
            if let event = store.selectedTransaction {
                selectedDetail(event)
            } else {
                companionHub
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .applyNighthawkBackground()
    }

    private var companionHub: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Nighthawk.HomeScreen.wallet)
                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)

            syncCard

            if let address = store.walletInfo.unifiedAddress?.stringEncoded, !address.isEmpty {
                receiveCard(address)
            }

            Text(L10n.Nighthawk.WalletCompanion.shieldedNote)
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
        }
        .padding(20)
    }

    private var syncCard: some View {
        let method = store.walletInfo.synchronizerState.activeSyncMethod
        let title: String = {
            switch method {
            case .trialDecrypt:
                return L10n.Nighthawk.WalletCompanion.trialDecrypt
            case .unifOmr:
                return L10n.Nighthawk.WalletCompanion.unifOmr
            case .unknown:
                return L10n.General.unknown
            }
        }()
        let height = store.walletInfo.synchronizerState.latestBlockHeight
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
            Text(height > 0 ? L10n.Nighthawk.WalletCompanion.blockHeight(height) : L10n.Nighthawk.WalletCompanion.waitingForHeight)
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
            if method == .trialDecrypt {
                Text(L10n.Nighthawk.WalletCompanion.trialActive)
                    .caption(color: Asset.Colors.Nighthawk.peach.color)
            } else if method == .unifOmr {
                Text(L10n.Nighthawk.WalletCompanion.syncedUnifOmr)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
            }
            let fallback = store.walletInfo.synchronizerState.fallbackUserMessage
            if !fallback.isEmpty {
                Text(fallback)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Asset.Colors.Nighthawk.navy.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func receiveCard(_ address: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Nighthawk.WalletCompanion.receive)
                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
            if let image = QRCodeGenerator.generate(from: address, scale: 8) {
                Image(decorative: image, scale: 1)
                    .accessibilityLabel(L10n.Nighthawk.WalletCompanion.receive)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
            }
            Text(address)
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Asset.Colors.Nighthawk.navy.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func selectedDetail(_ event: WalletEvent) -> some View {
        let tx = event.transaction
        let memo = tx.textMemo?.toString()
        return VStack(alignment: .leading, spacing: 16) {
            Text(tx.isSending ? L10n.Nighthawk.Transaction.sent : L10n.Nighthawk.Transaction.received)
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
            Text("\(tx.zecAmount.decimalString()) \(store.tokenName)")
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 28))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
            if let date = tx.date {
                Text(date.asHumanReadable())
                    .caption()
            }
            if let memo, !memo.isEmpty {
                Text(memo)
                    .caption(color: Asset.Colors.Nighthawk.textHeader.color)
            }
            if let address = tx.address, !address.isEmpty {
                Text(address)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    .textSelection(.enabled)
            }
            Text(tx.id)
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                .textSelection(.enabled)

            nextSteps(tx: tx, memo: memo)
        }
        .padding(20)
    }

    private func nextSteps(tx: TransactionState, memo: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Nighthawk.WalletCompanion.nextSteps)
                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
            Button(L10n.Nighthawk.WalletCompanion.copyTxId) {
                store.send(.copyTransactionId(tx.id))
            }
            .buttonStyle(.nighthawkSecondary())
            if tx.isSending, let address = tx.address, !address.isEmpty {
                Button(L10n.Nighthawk.WalletCompanion.sendAgain) {
                    store.send(.sendAgainTapped)
                }
                .buttonStyle(.nighthawkPrimary())
            }
            if let memo, !memo.isEmpty {
                Button(L10n.Nighthawk.WalletCompanion.copyMemo) {
                    store.send(.copyMemo(memo))
                }
                .buttonStyle(.nighthawkSecondary())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Asset.Colors.Nighthawk.navy.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
