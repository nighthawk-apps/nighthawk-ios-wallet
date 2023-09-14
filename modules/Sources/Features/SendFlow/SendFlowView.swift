//
//  SendFlowView.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct SendFlowView: View {
    let store: StoreOf<SendFlow>
    let tokenName: String
    
    public init(store: StoreOf<SendFlow>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        NavigationStackStore(
            store.scope(
                state: \.path,
                action: { .path($0) }
            )
        ) {
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
                    state: /SendFlow.Path.State.addMemo,
                    action: SendFlow.Path.Action.addMemo,
                    then: AddMemoView.init(store:)
                )
            case .failed:
                CaseLet(
                    state: /SendFlow.Path.State.failed,
                    action: SendFlow.Path.Action.failed,
                    then: FailedView.init(store:)
                )
            case .recipient:
                CaseLet(
                    state: /SendFlow.Path.State.recipient,
                    action: SendFlow.Path.Action.recipient,
                    then: RecipientView.init(store:)
                )
            case .review:
                CaseLet(
                    state: /SendFlow.Path.State.review,
                    action: SendFlow.Path.Action.review,
                    then: { store in
                        ReviewView(store: store, tokenName: tokenName)
                    }
                )
            case .scan:
                CaseLet(
                    state: /SendFlow.Path.State.scan,
                    action: SendFlow.Path.Action.scan,
                    then: ScanView.init(store:)
                )
            case .sending:
                CaseLet(
                    state: /SendFlow.Path.State.sending,
                    action: SendFlow.Path.Action.sending,
                    then: SendingView.init(store:)
                )
            case .success:
                CaseLet(
                    state: /SendFlow.Path.State.success,
                    action: SendFlow.Path.Action.success,
                    then: SuccessView.init(store:)
                )
            }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension SendFlowView {
    func amountToSend(with viewStore: ViewStoreOf<SendFlow>) -> some View {
        VStack {
            NighthawkTransactionAmountTextField(
                text: viewStore.binding(\.$amountToSendInput).animation(),
                tokenName: tokenName
            )
            .frame(maxWidth: .infinity)
        }
    }
    
    func availableActions(with viewStore: ViewStoreOf<SendFlow>) -> some View {
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
