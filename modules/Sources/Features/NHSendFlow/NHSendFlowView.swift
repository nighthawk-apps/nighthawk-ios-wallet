//
//  NHSendFlowView.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct NHSendFlowView: View {
    let store: NHSendFlowStore
    let tokenName: String
    
    public init(store: NHSendFlowStore, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        NavigationStackStore(store.stackStore()) {
            WithViewStore(store) { viewStore in
                VStack {
                    NighthawkHeading(title: L10n.Nighthawk.TransferTab.Send.chooseHowMuch)
                    
                    Text(
                        L10n.Nighthawk.TransferTab.Send.spendableBalance(
                            viewStore.maxAmount.decimalString(
                                formatter: NumberFormatter.zcashNumberFormatter
                            ),
                            tokenName
                        )
                    )
                    .paragraphMedium()
                    .padding(.bottom, 40)
                    
                    amountToSend(with: viewStore)
                    
                    Spacer()
                    
                    availableActions(with: viewStore)
                }
                .onAppear { viewStore.send(.onAppear) }
            }
            .applyNighthawkBackground()
        } destination: { state in
            switch state {
            case .addMemo:
                CaseLet(
                    state: /NHSendFlowReducer.Path.State.addMemo,
                    action: NHSendFlowReducer.Path.Action.addMemo,
                    then: AddMemoView.init(store:)
                )
            case .failed:
                CaseLet(
                    state: /NHSendFlowReducer.Path.State.failed,
                    action: NHSendFlowReducer.Path.Action.failed,
                    then: FailedView.init(store:)
                )
            case .recipient:
                CaseLet(
                    state: /NHSendFlowReducer.Path.State.recipient,
                    action: NHSendFlowReducer.Path.Action.recipient,
                    then: RecipientView.init(store:)
                )
            case .review:
                CaseLet(
                    state: /NHSendFlowReducer.Path.State.review,
                    action: NHSendFlowReducer.Path.Action.review,
                    then: { store in
                        ReviewView(store: store, tokenName: tokenName)
                    }
                )
            case .scan:
                CaseLet(
                    state: /NHSendFlowReducer.Path.State.scan,
                    action: NHSendFlowReducer.Path.Action.scan,
                    then: NHScanView.init(store:)
                )
            case .sending:
                CaseLet(
                    state: /NHSendFlowReducer.Path.State.sending,
                    action: NHSendFlowReducer.Path.Action.sending,
                    then: SendingView.init(store:)
                )
            case .success:
                CaseLet(
                    state: /NHSendFlowReducer.Path.State.success,
                    action: NHSendFlowReducer.Path.Action.success,
                    then: SuccessView.init(store:)
                )
            }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension NHSendFlowView {
    func amountToSend(with viewStore: NHSendFlowViewStore) -> some View {
        VStack {
            NHTransactionAmountTextField(
                text: viewStore.binding(\.$amountToSendInput).animation(),
                tokenName: tokenName
            )
            .frame(maxWidth: .infinity)
        }
    }
    
    func availableActions(with viewStore: NHSendFlowViewStore) -> some View {
        Group {
            if viewStore.amountToSend > .zero {
                Button(
                    viewStore.canSendEnteredAmount
                    ? L10n.Nighthawk.TransferTab.Send.continue
                    : L10n.Nighthawk.TransferTab.Send.topUpWallet,
                    action: {
                        viewStore.send(
                            viewStore.canSendEnteredAmount
                            ? .continueTapped
                            : .topUpWalletTapped
                        )
                    }
                )
                .buttonStyle(.nighthawkPrimary())
                .padding(.bottom, 28)
            } else {
                Button(
                    L10n.Nighthawk.TransferTab.Send.scanCode,
                    action: { viewStore.send(.scanCodeTapped) }
                )
                .buttonStyle(.nighthawkDashed())
                .padding(.bottom, 28)
            }
        }
    }
}
