//
//  ReceiveView.swift
//  
//
//  Created by Matthew on 7/15/23.
//

import AlertToast
import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct ReceiveView: View {
    @Bindable var store: StoreOf<Receive>
    
    public init(store: StoreOf<Receive>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            NighthawkLogo(spacing: .compact)
                .padding(.vertical, 40)
            
            VStack(spacing: 10) {
                secureOptionsList
                
                publicOptionsList
            }
            
            Spacer()
        }
        .toast(
            unwrapping: $store.toast,
            case: /Receive.State.Toast.copiedToClipboard,
            alert: {
                AlertToast(
                    type: .regular,
                    title: L10n.Nighthawk.WalletTab.Addresses.copiedToClipboard
                )
            }
        )
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
    }
}

// MARK: - Subviews
private extension ReceiveView {
    var secureOptionsList: some View {
        VStack(spacing: 10) {
            HStack {
                Text(L10n.Nighthawk.TransferTab.Receive.receiveMoneySecurely)
                    .paragraphMedium()
                Spacer()
            }
            
            Button(action: { store.send(.showQrCodeTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.Receive.showQrCodeTitle,
                    description: L10n.Nighthawk.TransferTab.sendMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.nhQrCode.image
                )
            }
            
            Button(action: { store.send(.copyUnifiedAddressTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.Receive.copyUnifiedAddressTitle,
                    description: L10n.Nighthawk.TransferTab.Receive.copyUnifiedAddressDescription,
                    icon: Asset.Assets.Icons.Nighthawk.copy.image
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
    
    var publicOptionsList: some View {
        VStack(spacing: 10) {
            HStack {
                Text(L10n.Nighthawk.TransferTab.Receive.receiveMoneyPublicly)
                    .paragraphMedium()
                    .padding(.top, 10)
                Spacer()
            }
            
            Button(action: { store.send(.copyTransparentAddressTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.Receive.copyNonPrivateAddressTitle,
                    description: L10n.Nighthawk.TransferTab.Receive.copyNonPrivateAddressDescription,
                    icon: Asset.Assets.Icons.Nighthawk.unshielded.image
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
