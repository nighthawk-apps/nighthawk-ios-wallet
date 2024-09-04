import AlertToast
import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents
import ZcashLightClientKit

public struct TransactionDetailView: View {
    let store: StoreOf<TransactionDetail>
    let tokenName: String
    
    public init(store: StoreOf<TransactionDetail>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView([.vertical]) {
                NighthawkHeading(title: L10n.Nighthawk.TransactionDetails.title)
                    .padding(.bottom, 24)
                
                if !viewStore.isLoaded {
                    Text(L10n.Nighthawk.TransactionDetails.notAvailable)
                        .caption()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    Group {
                        transactionSummary(with: viewStore)
                        
                        TransactionDetailsTable(lineItems: viewStore.transactionLineItems(with: tokenName))
                    }
                }
            }
            .onAppear { viewStore.send(.onAppear) }
            .toast(
                unwrapping: viewStore.$toast,
                case: /TransactionDetail.State.Toast.replyToCopied,
                alert: {
                    AlertToast(
                        type: .regular,
                        title: L10n.Nighthawk.TransactionDetails.replyToCopied
                    )
                }
            )
        }
        .applyNighthawkBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
}

// MARK: - Transaction Line Items
private extension ViewStoreOf<TransactionDetail> {
    // TODO: Consider using ResultBuilder for this.
    func transactionLineItems(with tokenName: String) -> [TransactionLineItem] {
        var result: [TransactionLineItem] = []
        if let memoText = self.memo?.toString() {
            result.append(
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.memo,
                    value: memoText,
                    isMemo: true,
                    action: .tap(
                        action: {
                            self.send(.copyReplyTo)
                        }
                    )
                )
            )
        }
        
        result.append(
            contentsOf: [
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.time,
                    value: "\(self.date?.timestamp() ?? L10n.General.dateNotAvailable)"
                )
            ]
        )
        
        if let minedHeight = self.minedHeight, minedHeight > 0 {
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
                    value: "\(self.confirmations)"
                ),
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.transactionId,
                    value: self.id,
                    action: .button(
                        title: L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer,
                        action: {
                            self.send(.warnBeforeLeavingApp(self.viewOnlineURL))
                        }
                    )
                )
            ]
        )
        
        if self.isSending, let address = self.address {
            result.append(
                contentsOf: [
                    TransactionLineItem(
                        name: L10n.Nighthawk.TransactionDetails.recipient,
                        value: self.shielded
                        ? L10n.Nighthawk.TransactionDetails.recipientShielded
                        : L10n.Nighthawk.TransactionDetails.recipientTransparent,
                        showBorder: false
                    ),
                    TransactionLineItem(
                        name: L10n.Nighthawk.TransactionDetails.address,
                        value: address,
                        action: .button(
                            title: L10n.Nighthawk.TransactionDetails.viewOnBlockExplorer,
                            action: {
                                self.send(.warnBeforeLeavingApp(self.viewRecipientOnlineURL))
                            }
                        )
                    )
                ]
            )
        }
        
        if self.isSending {
            result.append(
                contentsOf: [
                    TransactionLineItem(
                        name: L10n.Nighthawk.TransactionDetails.networkFee,
                        value: "\(self.fee.decimalString()) \(tokenName)"
                    )
                ]
            )
        }
        
        result.append(
            contentsOf: [
                TransactionLineItem(
                    name: L10n.Nighthawk.TransactionDetails.totalAmount,
                    value: "\(self.zecAmount.decimalString()) \(tokenName)"
                )
            ]
        )
        
        return result
    }
}

// MARK: - Sections
private extension TransactionDetailView {
    func transactionSummary(with viewStore: ViewStoreOf<TransactionDetail>) -> some View {
        VStack {
            summaryIcon(for: viewStore.status)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
            
            VStack {
                HStack(alignment: .center) {
                    Group {
                        Text("\(viewStore.zecAmount.decimalString())")
                            .foregroundColor(.white)
                        
                        Text(tokenName)
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    }
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 28))
                }
                
                if let (currency, price) = viewStore.fiatConversion {
                    Text(
                        L10n.Nighthawk.TransactionDetails.Fiat.around(
                            (price * viewStore.zecAmount.decimalValue.doubleValue).currencyString,
                            currency.rawValue.uppercased()
                        )
                    )
                    .paragraphMedium()
                }
            }
            
            TransactionStatusView(status: viewStore.status)
                .padding(.top, 22)
        }
    }
}

// MARK: - Helpers
private extension TransactionDetailView {
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
