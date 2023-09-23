//
//  NighthawkTabBar.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import Generated
import SwiftUI

struct NighthawkTabBar: View {
    let destination: Binding<Home.State.Tab>
    let disableSend: Bool
    
    init(
        destination: Binding<Home.State.Tab>,
        disableSend: Bool
    ) {
        self.destination = destination
        self.disableSend = disableSend
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        HStack {
            Tab(
                title: L10n.Nighthawk.HomeScreen.wallet,
                image: Asset.Assets.Icons.Nighthawk.wallet.image,
                isSelected: destination.wrappedValue == .wallet
            )
            .onTapGesture { destination.wrappedValue = .wallet }
                        
            Tab(
                title: L10n.Nighthawk.HomeScreen.transfer,
                image: Asset.Assets.Icons.Nighthawk.transfer.image,
                isSelected: destination.wrappedValue == .transfer
            )
            .onTapGesture { destination.wrappedValue = .transfer }
            .disable(when: disableSend, dimmingOpacity: 0.3)
                        
            Tab(
                title: L10n.Nighthawk.HomeScreen.settings,
                image: Asset.Assets.Icons.Nighthawk.settings.image,
                isSelected: destination.wrappedValue == .settings
            )
            .onTapGesture {
                destination.wrappedValue = .settings
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 54)
        .edgesIgnoringSafeArea([.bottom])
        .background(Asset.Colors.Nighthawk.navy.color)
    }
}

struct Tab: View {
    let title: String
    let image: Image
    let isSelected: Bool
    
    var body: some View {
        VStack {
            image
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(
                    isSelected
                    ? Asset.Colors.Nighthawk.peach.color
                    : .white
                )
                .frame(width: 24, height: 24)
            Text(title)
                .caption(
                    color: isSelected
                    ? Asset.Colors.Nighthawk.peach.color
                    : .white
                )
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    isSelected
                    ? Asset.Colors.Nighthawk.peach.color
                    : .clear
                )
                .frame(height: 4)
                .frame(maxWidth: .infinity)
        }
    }
}
