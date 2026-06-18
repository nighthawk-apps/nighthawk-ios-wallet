//
//  TransferView.swift
//  stealth
//
//  Created by Matthew watt on 5/5/23.
//

import ComposableArchitecture
import Generated
import Receive
import SendFlow
import SwiftUI

import UIComponents

struct TransferView: View {
    @Bindable var store: StoreOf<Transfer>
    
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
                state: \.destination?.send,
                action: \.destination.send
            )
        ) { store in
            SendFlowView(store: store)
        }
    }
}

// MARK: - Subviews
private extension TransferView {
    @ViewBuilder var heading: some View {
        NighthawkLogo(spacing: .compact, size: .tabHeader)
            .padding(.vertical, 24)
        
        HStack {
            Text(L10n.Nighthawk.TransferTab.sendAndReceiveDrk)
                .paragraphMedium(color: .white)
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
            .buttonStyle(.plain)
            .accessibilityIdentifier("nighthawk.transfer.send")
            
            Button(action: { store.send(.receiveMoneyTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.receiveMoneyTitle,
                    description: L10n.Nighthawk.TransferTab.receiveMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.received.image
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("nighthawk.transfer.receive")
            
            Button(action: { store.send(.daoHubTapped) }) {
                optionRow(
                    title: "DAO Hub",
                    description: "Browse DAOs, proposals, and governance details for your wallet.",
                    icon: Image(systemName: "building.columns")
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("nighthawk.transfer.daoHub")
            
            Button(action: { store.send(.topUpWalletTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.topUpWalletTitle,
                    description: L10n.Nighthawk.TransferTab.topUpWalletDescription,
                    icon: Asset.Assets.Icons.Nighthawk.topUp.image
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("nighthawk.transfer.topUp")
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
