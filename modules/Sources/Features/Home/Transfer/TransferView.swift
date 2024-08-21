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
    @Bindable var store: StoreOf<Transfer>
    let tokenName: String
    
    var body: some View {
        VStack {
            heading
            
            optionsList
            
            Spacer()
        }
        .applyNighthawkBackground()
        .sheet(
            item: $store.scope(
                state: \.destination?.receive,
                action: \.destination.receive
            )
        ) { store in
            ReceiveView(store: store)
        }
        .sheet(
            item: $store.scope(
                state: \.destination?.topUp,
                action: \.destination.topUp
            )
        ) { store in
            TopUpView(store: store)
        }
        .sheet(
            item: $store.scope(
                state: \.destination?.send,
                action: \.destination.send
            )
        ) { store in
            SendFlowView(store: store, tokenName: tokenName)
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
    
    var optionsList: some View {
        VStack(spacing: 10) {
            Button(action: { store.send(.sendMoneyTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.sendMoneyTitle,
                    description: L10n.Nighthawk.TransferTab.sendMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.sent.image
                )
            }
            
            Button(action: { store.send(.receiveMoneyTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.receiveMoneyTitle,
                    description: L10n.Nighthawk.TransferTab.receiveMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.received.image
                )
            }
            
            Button(action: { store.send(.topUpWalletTapped) }) {
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
