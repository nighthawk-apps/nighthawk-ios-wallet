//
//  SendFlowView.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import AlertToast
import ComposableArchitecture
import Generated
import SDKSynchronizer
import SwiftUI
import UIComponents

@MainActor
public struct SendFlowView: View {
    @Bindable var store: StoreOf<SendFlow>
    
    public var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \.path,
                action: \.path
            )
        ) {
            VStack {
                NighthawkHeading(title: L10n.Nighthawk.TransferTab.Send.chooseHowMuch)
                
                Text(
                    L10n.Nighthawk.TransferTab.Send.spendableBalance(
                        store.spendableBalance.decimalString(
                            formatter: NumberFormatter.zcashNumberFormatter
                        ),
                        store.tokenName
                    )
                )
                .paragraphMedium()
                .padding(.bottom, store.availableTokens.count > 1 ? 16 : 40)
                
                // Token picker — only shown when wallet has multiple tokens
                if store.availableTokens.count > 1 {
                    tokenPicker
                        .padding(.bottom, 24)
                }
                
                amountToSend
                
                Spacer()
                
                availableActions
            }
            .onAppear { store.send(.onAppear) }
            .modify {
                if store.showCloseButton {
                    $0.showNighthawkBackButton(type: .close) {
                        store.send(.closeButtonTapped)
                    }
                } else {
                    $0
                }
            }
            .alert(
                $store.scope(
                    state: \.alert,
                    action: \.alert
                )
            )
            .toast(
                unwrapping: $store.toast,
                case: /SendFlow.State.Toast.notEnoughDrk,
                alert: {
                    AlertToast(
                        type: .regular,
                        title: L10n.Nighthawk.TransferTab.Send.Toast.notEnoughDrk
                    )
                }
            )
            .applyNighthawkBackground()
        } destination: { store in
            switch store.case {
            case let .addMemo(store):
                AddMemoView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
                
            case let .failed(store):
                SendFailedView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
                
            case let .recipient(store):
                RecipientView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
                
            case let .review(store):
                ReviewView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
                
            case let .scan(store):
                ScanView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
                
            case .sending:
                SendingView()
                    .toolbar(.hidden, for: .navigationBar)
            case let .success(store):
                SendSuccessView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<SendFlow>) {
        self.store = store
    }
}

// MARK: - Subviews
private extension SendFlowView {
    var amountToSend: some View {
        VStack {
            NighthawkTransactionAmountTextField(
                text: $store.amountToSendInput.animation(),
                tokenName: store.tokenName
            )
            .frame(maxWidth: .infinity)
            
            if let (currency, price) = store.fiatConversion, store.hasEnteredAmount {
                Text(
                    L10n.Nighthawk.TransferTab.Send.around(
                        (price * store.amountToSend.decimalValue.doubleValue).currencyString,
                        currency.rawValue.uppercased()
                    )
                )
                .paragraphMedium()
            }
        }
    }
    
    var availableActions: some View {
        Group {
            if store.amountToSend > .zero {
                Button(
                    store.canSendEnteredAmount
                    ? L10n.Nighthawk.TransferTab.Send.continue
                    : L10n.Nighthawk.TransferTab.Send.topUpWallet,
                    action: {
                        store.send(
                            store.canSendEnteredAmount
                            ? .continueTapped
                            : .topUpWalletTapped
                        )
                    }
                )
                .buttonStyle(.nighthawkPrimary())
                .padding(.bottom, 28)
            } else if store.showScanButton {
                Button(
                    L10n.Nighthawk.TransferTab.Send.scanCode,
                    action: { store.send(.scanCodeTapped) }
                )
                .buttonStyle(.nighthawkDashed())
                .padding(.bottom, 28)
            }
        }
    }
    
    var tokenPicker: some View {
        Menu {
            // Native DRK option (nil tokenId)
            Button {
                store.send(.tokenSelected(nil))
            } label: {
                HStack {
                    Text("DRK (native)")
                    if store.selectedTokenId == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            // Other tokens from wallet
            ForEach(store.availableTokens, id: \.tokenId) { token in
                Button {
                    store.send(.tokenSelected(token.tokenId))
                } label: {
                    HStack {
                        Text(token.displayLabel ?? token.tokenId.prefix(8) + "…")
                        Spacer()
                        Text(Self.formatAtomicBalance(token.balanceAtomic))
                        if store.selectedTokenId == token.tokenId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("Token:")
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                
                Text(store.tokenName)
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 14))
                    .foregroundColor(.white)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Asset.Colors.Nighthawk.navy.color.opacity(0.5))
            )
        }
    }
    
    static func formatAtomicBalance(_ atomic: Int64) -> String {
        let drk = Double(atomic) / 100_000_000.0
        return String(format: "%.4f", drk)
    }
}
