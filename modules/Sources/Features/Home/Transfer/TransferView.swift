//
//  TransferView.swift
//  secant
//
//  Created by Matthew watt on 5/5/23.
//

import ComposableArchitecture
import Generated
import Receive
import SendFlow
import SwiftUI
import TopUp
import UIComponents

struct TransferView: View {
    let store: StoreOf<Transfer>
    let tokenName: String
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                heading
                
                optionsList(with: viewStore)
                
                Spacer()
            }
        }
        .applyNighthawkBackground()
        .sheet(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /Transfer.Destination.State.receive,
            action: Transfer.Destination.Action.receive
        ) { store in
            ReceiveView(store: store)
                .interactiveDismissDisabled()
        }
        .sheet(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /Transfer.Destination.State.topUp,
            action: Transfer.Destination.Action.topUp
        ) { store in
            TopUpView(store: store)
                .interactiveDismissDisabled()
        }
        .sheet(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /Transfer.Destination.State.send,
            action: Transfer.Destination.Action.send
        ) { store in
            SendFlowView(store: store, tokenName: tokenName)
                .interactiveDismissDisabled()
        }
    }
}

// MARK: - Subviews
private extension TransferView {
    @ViewBuilder var heading: some View {
        NighthawkLogo(spacing: .compact)
            .padding(.vertical, 40)
        
        HStack {
            Text(L10n.Nighthawk.TransferTab.sendAndReceiveZcash)
                .paragraphMedium()
            Spacer()
        }
        .padding(.horizontal, 25)
    }
    
    func optionsList(with viewStore: ViewStoreOf<Transfer>) -> some View {
        VStack(spacing: 10) {
            Button(action: { viewStore.send(.sendMoneyTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.sendMoneyTitle,
                    description: L10n.Nighthawk.TransferTab.sendMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.sent.image
                )
            }
            
            Button(action: { viewStore.send(.receiveMoneyTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.receiveMoneyTitle,
                    description: L10n.Nighthawk.TransferTab.receiveMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.received.image
                )
            }
            
            Button(action: { viewStore.send(.topUpWalletTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.topUpWalletTitle,
                    description: L10n.Nighthawk.TransferTab.topUpWalletDescription,
                    icon: Asset.Assets.Icons.Nighthawk.topUp.image
                )
            }
        }
        .padding(.horizontal, 25)
    }
    
    func optionRow(
        title: String,
        description: String,
        icon: Image
    ) -> some View {
        VStack {
            HStack(alignment: .center) {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .padding(.trailing, 14)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    
                    Text(description)
                        .caption()
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            Divider()
                .frame(height: 2)
                .overlay(Asset.Colors.Nighthawk.navy.color)
        }
    }
}
