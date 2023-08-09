import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents
import ZcashLightClientKit

public struct NHTransactionDetailView: View {
    let store: NHTransactionDetailStore
    let tokenName: String

    public init(store: NHTransactionDetailStore, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView([.vertical]) {
                NighthawkHeading(title: L10n.Nighthawk.TransactionDetails.title)
                    .padding(.bottom, 24)

                transactionSummary(with: viewStore)

                TransactionDetailsTable(lineItems: viewStore.transactionLineItems(with: tokenName))

                Button(L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer) {
                    viewStore.send(.warnBeforeLeavingApp(viewStore.transaction.viewOnlineURL))
                }
                .buttonStyle(.nighthawkPrimary())
                .padding(.bottom, 30)
            }
            .onAppear { viewStore.send(.onAppear) }
        }
        .applyNighthawkBackground()
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
}

// MARK: - Transaction Line Items
private extension NHTransactionDetailViewStore {
    // TODO: Consider using ResultBuilder for this.
    func transactionLineItems(with tokenName: String) -> [TransactionLineItem] {
        var result: [TransactionLineItem] = []
        if let memoText = self.transaction.memos?.first?.toString() {
            result.append(
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.memo,
                    value: memoText,
                    isMemo: true
                )
            )
        }
        
        result.append(
            contentsOf: [
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.time,
                    value: "\(self.transaction.date?.timestamp() ?? L10n.General.dateNotAvailable)"
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.pool,
                    value: "\(self.transaction.shielded ? L10n.Nighthawk.TransactionDetails.sapling : L10n.Nighthawk.TransactionDetails.transparent)"
                )
            ]
        )
        
        if let minedHeight = self.transaction.minedHeight, minedHeight > 0 {
            result.append(
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.blockId,
                    value: "\(String(minedHeight))"
                )
            )
        } else {
            result.append(
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.blockId,
                    value: L10n.Nighthawk.TransactionDetails.unconfirmed
                )
            )
        }
        
        result.append(
            contentsOf: [
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.confirmations,
                    value: "\(self.transaction.confirmationsWith(self.latestMinedHeight))"
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.transactionId,
                    value: self.transaction.id,
                    action: .init(
                        title: L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer,
                        action: {
                            self.send(.warnBeforeLeavingApp(self.transaction.viewOnlineURL))
                        }
                    )
                )
            ]
        )
        
        if self.transaction.isSending {
            result.append(
                contentsOf: [
                    TransactionLineItem(
                        name: L10n.Nighthawk.TransactionDetails.recipient,
                        value: self.transaction.shielded
                            ? L10n.Nighthawk.TransactionDetails.recipientShielded
                            : L10n.Nighthawk.TransactionDetails.recipientTransparent,
                        showBorder: false
                    ),
                    TransactionLineItem(
                        name: L10n.Nighthawk.TransactionDetails.address,
                        value: self.transaction.address,
                        action: .init(
                            title: L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer,
                            action: {
                                self.send(.warnBeforeLeavingApp(self.transaction.viewRecipientOnlineURL))
                            }
                        )
                    )
                ]
            )
        }
        
        result.append(
            contentsOf: [
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.subtotal,
                    value: "\(self.transaction.zecAmount.decimalString()) \(tokenName)",
                    showBorder: false
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.networkFee,
                    value: "\(self.transaction.fee.decimalString()) \(tokenName)"
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.totalAmount,
                    value: "\(self.transaction.totalAmount.decimalString()) \(tokenName)"
                )
            ]
        )
        
        return result
    }
}

// MARK: - Sections
private extension NHTransactionDetailView {
    func transactionSummary(with viewStore: NHTransactionDetailViewStore) -> some View {
        VStack {
            summaryIcon(for: viewStore.transaction.status)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
            
            HStack(alignment: .center) {
                Group {
                    Text("\(viewStore.transaction.zecAmount.decimalString())")
                        .foregroundColor(.white)
                    
                    Text(tokenName)
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                }
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 28))
            }
            
            TransactionStatusView(status: viewStore.transaction.status)
                .padding(.top, 22)
        }
    }
}

// MARK: - Helpers
private extension NHTransactionDetailView {
    func summaryIcon(for status: TransactionState.Status) -> Image {
        switch status {
        case .paid(success: true), .sending:
            return Asset.Assets.Icons.Nighthawk.sent.image
        case .received, .receiving:
            return Asset.Assets.Icons.Nighthawk.received.image
        case .failed, .paid(success: false):
            return Asset.Assets.Icons.Nighthawk.error.image
        }
    }
}

private extension TransactionState {
    var isSending: Bool {
        switch status {
        case .paid, .sending:
            return true
        default:
            return false
        }
    }
}
