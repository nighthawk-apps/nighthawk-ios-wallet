import ComposableArchitecture
import Generated
import Models
import Utils
import SwiftUI
import WalletEventsFlow
import ZcashLightClientKit

public struct NHTransactionDetailView: View {
    enum RowMark {
        case neutral
        case success
        case fail
        case inactive
        case highlight
    }

    let latestMinedHeight: BlockHeight?
    let requiredTransactionConfirmations: Int
    let tokenName: String
    let transaction: TransactionState

    public init(
        latestMinedHeight: BlockHeight?,
        requiredTransactionConfirmations: Int,
        tokenName: String,
        transaction: TransactionState
    ) {
        self.latestMinedHeight = latestMinedHeight
        self.requiredTransactionConfirmations = requiredTransactionConfirmations
        self.tokenName = tokenName
        self.transaction = transaction
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            header

            HStack {
                VStack(alignment: .leading) {
                    switch transaction.status {
                    case .paid:
                        Text(L10n.Transaction.youSent(transaction.zecAmount.decimalString(), tokenName))
                            .padding()
                        address(mark: .inactive)
                        memo(transaction, mark: .highlight)
                        
                    case .sending:
                        Text(L10n.Transaction.youAreSending(transaction.zecAmount.decimalString(), tokenName))
                            .padding()
                        address(mark: .inactive)
                        memo(transaction, mark: .highlight)
                    case .receiving:
                        Text(L10n.Transaction.youAreReceiving(transaction.zecAmount.decimalString(), tokenName))
                            .padding()
                        memo(transaction, mark: .highlight)
                    case .received:
                        Text(L10n.Transaction.youReceived(transaction.zecAmount.decimalString(), tokenName))
                            .padding()
                        address(mark: .inactive)
                        memo(transaction, mark: .highlight)
                    case .failed:
                        Text(L10n.Transaction.youDidNotSent(transaction.zecAmount.decimalString(), tokenName))
                            .padding()

                        address(mark: .inactive)
                        memo(transaction, mark: .highlight)

                        Text(L10n.TransactionDetail.error(transaction.errorMessage ?? L10n.General.unknown))
                            .padding()
                    }
                }
                
                Spacer()
            }

            Spacer()
        }
        .applyNighthawkBackground()
        .navigationTitle(L10n.TransactionDetail.title)
    }
}

extension NHTransactionDetailView {
    var header: some View {
        HStack {
            switch transaction.status {
            case .sending:
                Text(L10n.Transaction.sending)
                Spacer()
            case .receiving:
                Text(L10n.Transaction.receiving)
                Spacer()
            case .failed:
                Text("\(transaction.date?.asHumanReadable() ?? L10n.General.dateNotAvailable)")
            default:
                Text("\(transaction.date?.asHumanReadable() ?? L10n.General.dateNotAvailable)")
            }
        }
        .padding()
    }
    
    func address(mark: RowMark = .neutral) -> some View {
        Text("\(addressPrefixText) \(transaction.address)")
            .lineLimit(1)
            .truncationMode(.middle)
            .padding()
    }
    
    func memo(
        _ transaction: TransactionState,
        mark: RowMark = .neutral
    ) -> some View {
        Group {
            if let memoText = transaction.memos?.first?.toString() {
                VStack(alignment: .leading) {
                    Text(L10n.Transaction.withMemo)
                        .padding(.leading)
                    Text("\"\(memoText)\"")
                        .multilineTextAlignment(.leading)
                        .padding(.leading)
                }
            } else {
                EmptyView()
            }
        }
    }
    
    func confirmed(mark: RowMark = .neutral, latestMinedHeight: BlockHeight?) -> some View {
        HStack {
            Text(L10n.Transaction.confirmed)
            Spacer()
            Text(L10n.Transaction.confirmedTimes(transaction.confirmationsWith(latestMinedHeight)))
        }
        .nhTransactionDetailRow(mark: mark)
    }

    func confirming(mark: RowMark = .neutral) -> some View {
        HStack {
            Text(L10n.Transaction.confirming(requiredTransactionConfirmations))
            Spacer()
            Text("\(transaction.confirmationsWith(latestMinedHeight))/\(requiredTransactionConfirmations)")
        }
        .nhTransactionDetailRow(mark: mark)
    }
}

extension NHTransactionDetailView {
    var addressPrefixText: String {
        (transaction.status == .received || transaction.status == .receiving)
        ? "" : L10n.Transaction.to
    }
    
    var heightText: String {
        guard let minedHeight = transaction.minedHeight else { return L10n.Transaction.unconfirmed }
        return minedHeight > 0 ? String(minedHeight) : L10n.Transaction.unconfirmed
    }
}

// MARK: - Row modifier

struct NHTransactionDetailRow: ViewModifier {
    let mark: NHTransactionDetailView.RowMark
    let textColor: Color
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(backgroundColor)
            .padding(.leading, 20)
            .background(markColor(mark))
    }
    
    private func markColor(_ mark: NHTransactionDetailView.RowMark) -> Color {
        let markColor: Color
        
        switch mark {
        case .neutral: markColor = Asset.Colors.TransactionDetail.neutralMark.color
        case .success: markColor = Asset.Colors.TransactionDetail.succeededMark.color
        case .fail:  markColor = Asset.Colors.TransactionDetail.failedMark.color
        case .inactive:  markColor = Asset.Colors.TransactionDetail.inactiveMark.color
        case .highlight:  markColor = Asset.Colors.TransactionDetail.highlightMark.color
        }
        
        return markColor
    }
}

extension View {
    func nhTransactionDetailRow(
        mark: NHTransactionDetailView.RowMark = .neutral
    ) -> some View {
        modifier(
            NHTransactionDetailRow(
                mark: mark,
                textColor: mark == .inactive ?
                Asset.Colors.TransactionDetail.inactiveMark.color :
                Asset.Colors.Text.transactionDetailText.color,
                backgroundColor: Asset.Colors.BackgroundColors.numberedChip.color
            )
        )
    }
}
