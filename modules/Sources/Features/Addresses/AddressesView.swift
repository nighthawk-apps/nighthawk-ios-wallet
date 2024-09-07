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
                AlertToast(
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
        GeometryReader { geometry in
            tabs(geometry: geometry)
                .padding(.top, 16)
                .padding(.bottom, 64)
                .frame(maxHeight: geometry.size.width * 1.35)
        }
    }
    
    func tabs(geometry: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollView in
                HStack {
                    topUpView(seeMoreAction: { store.send(.topUpWalletTapped) })
                        .frame(width: geometry.size.width * 0.68)
                        .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                            effect.scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                        }
                    
                    addressView(
                        title: L10n.Nighthawk.WalletTab.Addresses.unifiedAddress,
                        address: store.unifiedAddress,
                        badge: Asset.Assets.Icons.Nighthawk.unifiedBadge.image,
                        copyAction: { store.send(.copyTapped(.unified)) }
                    )
                    .id("unified")
                    .frame(width: geometry.size.width * 0.68)
                    .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                        effect.scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                    }
                    
                    addressView(
                        title: L10n.Nighthawk.WalletTab.Addresses.saplingAddress,
                        address: store.saplingAddress,
                        badge: Asset.Assets.Icons.Nighthawk.saplingBadge.image,
                        copyAction: { store.send(.copyTapped(.sapling)) }
                    )
                    .frame(width: geometry.size.width * 0.68)
                    .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                        effect.scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                    }
                    
                    addressView(
                        title: L10n.Nighthawk.WalletTab.Addresses.transparentAddress,
                        address: store.transparentAddress,
                        badge: Asset.Assets.Icons.Nighthawk.transparentBadge.image,
                        copyAction: { store.send(.copyTapped(.transparent)) }
                    )
                    .frame(width: geometry.size.width * 0.68)
                    .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                        effect.scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                    }
                }
                .scrollTargetLayout()
                .onAppear {
                    scrollView.scrollTo("unified", anchor: .center)
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
        .safeAreaPadding(.horizontal, geometry.size.width * 0.16)
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
