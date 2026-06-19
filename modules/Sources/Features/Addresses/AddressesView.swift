//
//  AddressesView.swift
//  
//
//  Created by Matthew Watt on 7/16/23.
//

import AlertToast
import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents
import Utils

@MainActor
public struct AddressesView: View {
    private struct Contants {
        static let qrSize: CGFloat = 180
    }
    
    @Bindable var store: StoreOf<Addresses>
    
    public init(store: StoreOf<Addresses>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            NighthawkLogo(spacing: .compact)
                .padding(.top, 44)
            
            actionsCarousel
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .modify {
            if store.showCloseButton {
                $0.showNighthawkBackButton(type: .close) {
                    store.send(.closeButtonTapped)
                }
            } else {
                $0
            }
        }
        .toast(
            unwrapping: $store.toast,
            case: /Addresses.State.Toast.copiedToClipboard,
            alert: {
                AlertToast.nighthawkBanner(
                    type: .regular,
                    title: L10n.Nighthawk.WalletTab.Addresses.copiedToClipboard
                )
            }
        )
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension AddressesView {
    var actionsCarousel: some View {
        VStack(spacing: 0) {
            singleAddressCard
                .padding(.horizontal, 32)
                .padding(.top, 24)
        }
    }
    
    var singleAddressCard: some View {
        VStack {
            ScrollView([.vertical], showsIndicators: false) {
                VStack {
                    QRCodeContainer(
                        qrImage: qrCode(for: store.privacyAddress),
                        badge: Asset.Assets.Icons.Nighthawk.unifiedBadge.image
                    )
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                    
                    HStack {
                        Text("DarkFi Address")
                            .paragraphMedium()
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Text(store.privacyAddress)
                            .caption()
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            Button(
                L10n.Nighthawk.WalletTab.Addresses.copy,
                action: { store.send(.copyTapped(.unified)) }
            )
            .buttonStyle(.nighthawkPrimary())
        }
        .frame(maxHeight: .infinity)
        .padding(22)
        .background(Asset.Colors.Nighthawk.navy.color)
        .cornerRadius(10)
    }
    
    func qrCode(for qrText: String) -> Image {
        if let img = QRCodeGenerator.generate(from: qrText) {
            return Image(img, scale: 1, label: Text(L10n.qrCodeFor(qrText)))
        } else {
            return Image(systemName: "qrcode")
        }
    }
}
