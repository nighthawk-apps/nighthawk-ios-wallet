//
//  SendFlowView.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import AlertToast
import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

@MainActor
public struct SendFlowView: View {
    @Bindable var store: StoreOf<SendFlow>
    let tokenName: String
    
    public init(store: StoreOf<SendFlow>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
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
                        tokenName
                    )
                )
                .paragraphMedium()
                .padding(.bottom, 40)
                
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
                case: /SendFlow.State.Toast.notEnoughZcash,
                alert: {
                    AlertToast(
                        type: .regular,
                        title: L10n.Nighthawk.TransferTab.Send.Toast.notEnoughZcash
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
                ReviewView(store: store, tokenName: tokenName)
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
}

// MARK: - Subviews
private extension SendFlowView {
    var amountToSend: some View {
        VStack {
            NighthawkTransactionAmountTextField(
                text: $store.amountToSendInput.animation(),
                tokenName: tokenName
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
}
