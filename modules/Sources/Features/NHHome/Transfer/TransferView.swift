//
//  TransferView.swift
//  secant
//
//  Created by Matthew watt on 5/5/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

struct TransferView: View {
    let store: TransferStore
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                heading
                
                optionsList(with: viewStore)
                
                Spacer()
            }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension TransferView {
    @ViewBuilder var heading: some View {
        NighthawkLogo(spacing: .compact)
            .padding(.vertical, 40)
        
        HStack {
            Text(L10n.Nighthawk.TransferTab.sendAndReceiveZcash)
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
            Spacer()
        }
        .padding(.horizontal, 25)
    }
    
    func optionsList(with viewStore: TransferViewStore) -> some View {
        VStack(spacing: 10) {
            Button(action: {}) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.sendMoneyTitle,
                    description: L10n.Nighthawk.TransferTab.sendMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.send.image
                )
            }
            
            Button(action: {}) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.receiveMoneyTitle,
                    description: L10n.Nighthawk.TransferTab.receiveMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.receive.image
                )
            }
            
            Button(action: {}) {
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
