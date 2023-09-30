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
    
    let store: StoreOf<Addresses>
    
    public init(store: StoreOf<Addresses>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                NighthawkLogo(spacing: .compact)
                    .padding(.top, 44)
                
                actionsCarousel(with: viewStore)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .toast(
                unwrapping: viewStore.$toast,
                case: /Addresses.State.Toast.copiedToClipboard,
                alert: {
                    AlertToast(
                        type: .regular,
                        title: L10n.Nighthawk.WalletTab.Addresses.copiedToClipboard
                    )
                }
            )
        }
        .applyNighthawkBackground()
    }
}

// MARK: - NHPage
extension Addresses.State.Destination: NHPage {}

// MARK: - Subviews
private extension AddressesView {
    func actionsCarousel(with viewStore: ViewStoreOf<Addresses>) -> some View {
        GeometryReader { geometry in
            VStack {
                tabs(with: viewStore, geometry: geometry)
                
                NHPageIndicator(selection: viewStore.$destination)
            }
            .padding(.top, 16)
            .padding(.bottom, 64)
            .frame(maxHeight: geometry.size.width * 1.35)
        }
    }
    
    func tabs(with viewStore: ViewStoreOf<Addresses>, geometry: GeometryProxy) -> some View {
        TabView(selection: viewStore.$destination) {
            topUpView(seeMoreAction: { viewStore.send(.topUpWalletTapped) })
            .frame(maxWidth: geometry.size.width * 0.68)
            .tag(Addresses.State.Destination.topUp)
            
            addressView(
                title: L10n.Nighthawk.WalletTab.Addresses.unifiedAddress,
                address: viewStore.unifiedAddress,
                badge: Asset.Assets.Icons.Nighthawk.unifiedBadge.image,
                copyAction: { viewStore.send(.copyTapped(.unified)) }
            )
            .frame(maxWidth: geometry.size.width * 0.68)
            .tag(Addresses.State.Destination.unified)
            
            addressView(
                title: L10n.Nighthawk.WalletTab.Addresses.saplingAddress,
                address: viewStore.saplingAddress,
                badge: Asset.Assets.Icons.Nighthawk.saplingBadge.image,
                copyAction: { viewStore.send(.copyTapped(.sapling)) }
            )
            .frame(maxWidth: geometry.size.width * 0.68)
            .tag(Addresses.State.Destination.sapling)
            
            addressView(
                title: L10n.Nighthawk.WalletTab.Addresses.transparentAddress,
                address: viewStore.transparentAddress,
                badge: Asset.Assets.Icons.Nighthawk.transparentBadge.image,
                copyAction: { viewStore.send(.copyTapped(.transparent)) }
            )
            .frame(maxWidth: geometry.size.width * 0.68)
            .tag(Addresses.State.Destination.transparent)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    func addressView(
        title: String,
        address: String,
        badge: Image,
        copyAction: @escaping () -> Void
    ) -> some View {
        VStack {
            ScrollView([.vertical], showsIndicators: false) {
                VStack {
                    QRCodeContainer(
                        qrImage: qrCode(for: address),
                        badge: badge
                    )
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                    
                    HStack {
                        Text(title)
                            .paragraphMedium()
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Text(address)
                            .caption()
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            Button(
                L10n.Nighthawk.WalletTab.Addresses.copy,
                action: copyAction
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
    
    func topUpView(seeMoreAction: @escaping () -> Void) -> some View {
        VStack {
            HStack {
                Asset.Assets.Icons.Nighthawk.topUp.image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Spacer()
            }
            
            HStack {
                Text(L10n.Nighthawk.WalletTab.Addresses.topUpYourWallet)
                    .paragraphMedium()
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            HStack {
                Text(L10n.Nighthawk.WalletTab.Addresses.topUpYourWalletDescription)
                    .caption()
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            Spacer()
            
            Button(
                L10n.Nighthawk.WalletTab.Addresses.seeMore,
                action: seeMoreAction
            )
            .buttonStyle(.nighthawkPrimary())
        }
        .frame(maxHeight: .infinity)
        .padding(22)
        .background(Asset.Colors.Nighthawk.navy.color)
        .cornerRadius(10)
    }
}
