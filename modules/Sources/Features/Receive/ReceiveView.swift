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
    let store: StoreOf<Receive>
    
    public init(store: StoreOf<Receive>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                NighthawkLogo(spacing: .compact)
                    .padding(.vertical, 40)
                
                VStack(spacing: 10) {
                    secureOptionsList(with: viewStore)
                    
                    publicOptionsList(with: viewStore)
                }
                
                Spacer()
            }
            .toast(
                unwrapping: viewStore.$toast,
                case: /Receive.State.Toast.copiedToClipboard,
                alert: {
                    AlertToast(
                        type: .regular,
                        title: L10n.Nighthawk.WalletTab.Addresses.copiedToClipboard
                    )
                }
            )
            .onAppear {
                viewStore.send(.onAppear)
            }
            .showNighthawkBackButton(
                type: .close,
                action: {
                    viewStore.send(.closeTapped)
                }
            )
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension ReceiveView {
    func secureOptionsList(with viewStore: ViewStoreOf<Receive>) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(L10n.Nighthawk.TransferTab.Receive.receiveMoneySecurely)
                    .paragraphMedium()
                Spacer()
            }
            
            Button(action: { viewStore.send(.showQrCodeTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.Receive.showQrCodeTitle,
                    description: L10n.Nighthawk.TransferTab.sendMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.nhQrCode.image
                )
            }
            
            Button(action: { viewStore.send(.copyUnifiedAddressTapped) }) {
                optionRow(
                    title: L10n.Nighthawk.TransferTab.Receive.copyUnifiedAddressTitle,
                    description: L10n.Nighthawk.TransferTab.receiveMoneyDescription,
                    icon: Asset.Assets.Icons.Nighthawk.copy.image
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
    
    func publicOptionsList(with viewStore: ViewStoreOf<Receive>) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(L10n.Nighthawk.TransferTab.Receive.receiveMoneyPublicly)
                    .paragraphMedium()
                    .padding(.top, 10)
                Spacer()
            }
            
            Button(action: { viewStore.send(.copyTransparentAddressTapped) }) {
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
