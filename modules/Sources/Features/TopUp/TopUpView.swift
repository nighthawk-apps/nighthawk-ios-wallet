//
//  TopUpView.swift
//  
//
//  Created by Matthew Watt on 7/17/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct TopUpView: View {
    @Bindable var store: StoreOf<TopUp>
    
    public init(store: StoreOf<TopUp>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            NighthawkHeading(title: L10n.Nighthawk.TransferTab.sendAndReceiveZcash)
                .padding(.bottom, 40)
            
            partnersList
            
            Spacer()
        }
        .modify {
            if store.showCloseButton {
                $0.showNighthawkBackButton(type: .close) {
                    store.send(.closeButtonTapped)
                }
            } else {
                $0
            }
        }
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
}

// MARK: - Subviews
private extension TopUpView {
    var partnersList: some View {
        VStack(spacing: 10) {
            HStack {
                Text(L10n.Nighthawk.TransferTab.Receive.receiveMoneySecurely)
                    .paragraphMedium()
                    .padding(.top, 10)
                Spacer()
            }
            
            Button(action: { store.send(.showStealthExInstructions) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.TopUpWallet.stealthExIoTitle,
                    description: L10n.Nighthawk.TransferTab.TopUpWallet.stealthExIoDescription,
                    icon: Asset.Assets.Icons.Nighthawk.stealthex.image
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
