import ComposableArchitecture
import Generated
import Models
import SwiftUI
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
                heading
                
                transactionSummary(with: viewStore)
                
                transactionDetails(with: viewStore)
                
                Button(L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer) {
                    viewStore.send(.warnBeforeLeavingApp(viewStore.transaction.viewOnlineURL))
                }
                .buttonStyle(.nighthawkPrimary())
                .padding(.bottom, 30)
            }
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

// MARK: - Sections
private extension NHTransactionDetailView {
    var heading: some View {
        VStack(alignment: .center) {
            Asset.Assets.Icons.Nighthawk.nighthawkSymbolPeach
                .image
                .resizable()
                .frame(width: 35, height: 35)
                .padding(.bottom, 16)
            
            Text(L10n.Nighthawk.TransactionDetails.title)
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
        }
        .padding(.bottom, 24)
    }
    
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
    
    func transactionDetails(with viewStore: NHTransactionDetailViewStore) -> some View {
        VStack {
            // Basic details
            Group {
                memoRow(with: viewStore)
                
                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.parmaviolet.color)
                
                basicDetailRow(
                    name: L10n.Nighthawk.TransactionDetails.time,
                    value: "\(viewStore.transaction.date?.timestamp() ?? L10n.General.dateNotAvailable)"
                )
                
                basicDetailRow(
                    name: L10n.Nighthawk.TransactionDetails.pool,
                    value: "\(viewStore.transaction.shielded ? L10n.Nighthawk.TransactionDetails.sapling : L10n.Nighthawk.TransactionDetails.transparent)"
                )
                
                if let minedHeight = viewStore.transaction.minedHeight, minedHeight > 0 {
                    basicDetailRow(
                        name: L10n.Nighthawk.TransactionDetails.blockId,
                        value: "\(String(minedHeight))"
                    )
                } else {
                    basicDetailRow(
                        name: L10n.Nighthawk.TransactionDetails.blockId,
                        value: L10n.Nighthawk.TransactionDetails.unconfirmed
                    )
                }
                
                basicDetailRow(
                    name: L10n.Nighthawk.TransactionDetails.confirmations,
                    value: "\(viewStore.transaction.confirmationsWith(viewStore.latestMinedHeight))"
                )
            }
            
            // Actionable rows
            Group {
                detailWithActionRow(
                    name: L10n.Nighthawk.TransactionDetails.transactionId,
                    value: viewStore.transaction.id,
                    actionTitle: L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer,
                    action: {
                        viewStore.send(.warnBeforeLeavingApp(viewStore.transaction.viewOnlineURL))
                    }
                )
                
                if viewStore.transaction.isSending {
                    basicDetailRow(
                        name: L10n.Nighthawk.TransactionDetails.recipient,
                        value: viewStore.transaction.shielded ? L10n.Nighthawk.TransactionDetails.recipientShielded : L10n.Nighthawk.TransactionDetails.recipientTransparent,
                        showBorder: false
                    )
                    
                    detailWithActionRow(
                        name: L10n.Nighthawk.TransactionDetails.address,
                        value: viewStore.transaction.address,
                        actionTitle: L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer,
                        action: {
                            viewStore.send(.warnBeforeLeavingApp(viewStore.transaction.viewRecipientOnlineURL))
                        }
                    )
                }
            }
            
            Group {
                basicDetailRow(
                    name: L10n.Nighthawk.TransactionDetails.subtotal,
                    value: "\(viewStore.transaction.zecAmount.decimalString()) \(tokenName)",
                    showBorder: false
                )
                
                basicDetailRow(
                    name: L10n.Nighthawk.TransactionDetails.networkFee,
                    value: "\(viewStore.transaction.fee.decimalString()) \(tokenName)"
                )
                
                basicDetailRow(
                    name: L10n.Nighthawk.TransactionDetails.totalAmount,
                    value: "\(viewStore.transaction.totalAmount.decimalString()) \(tokenName)"
                )
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 55)
        .padding(.bottom, 40)
    }
    
    @ViewBuilder func memoRow(with viewStore: NHTransactionDetailViewStore) -> some View {
        if let memoText = viewStore.transaction.memos?.first?.toString() {
            HStack {
                VStack(alignment: .leading) {
                    Text(L10n.Nighthawk.TransactionDetails.memo)
                        .details()
                        .padding(.bottom, 4)
                    
                    Text(memoText)
                        .foregroundColor(.white)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                        .padding(.bottom, 22)
                }
                
                Spacer()
            }
        } else {
            EmptyView()
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
    
    func basicDetailRow(name: String, value: String, showBorder: Bool = true) -> some View {
        VStack {
            HStack(alignment: .center) {
                Text(name)
                    .details()
                Spacer()
                Text(value)
                    .details()
            }
            .padding(.vertical, 12)
            
            if showBorder {
                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.parmaviolet.color)
            }
        }
    }
    
    func detailWithActionRow(
        name: String,
        value: String,
        actionTitle: String,
        action: @escaping () -> Void,
        showBorder: Bool = true
    ) -> some View {
        VStack(alignment: .trailing) {
            VStack(alignment: .trailing) {
                HStack(alignment: .top) {
                    Text(name)
                        .details()
                    Spacer()
                    Text(value)
                        .details()
                        .multilineTextAlignment(.trailing)
                }
                .padding(.bottom, 10)
                
                Button(actionTitle, action: action)
                    .buttonStyle(.txnDetailsLink())
            }
            .padding(.vertical, 12)
            
            if showBorder {
                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.parmaviolet.color)
            }
        }
    }
}

private struct TransactionDetailsTextStyle: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
    }
}

private extension Text {
    func details(color: Color = Asset.Colors.Nighthawk.parmaviolet.color) -> some View {
        self.modifier(TransactionDetailsTextStyle(color: color))
    }
}

private struct TxnDetailsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TxnDetailsLinkButton(configuration: configuration)
    }
    
    struct TxnDetailsLinkButton: View {
        let configuration: ButtonStyle.Configuration
        var body: some View {
            configuration.label
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.peach.color.opacity(configuration.isPressed ? 0.5 : 1.0))
        }
    }
}

private extension ButtonStyle where Self == TxnDetailsButtonStyle {
    static func txnDetailsLink() -> TxnDetailsButtonStyle { TxnDetailsButtonStyle() }
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
