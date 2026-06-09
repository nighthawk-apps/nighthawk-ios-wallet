//
//  NighthawkTabBar.swift
//  stealth
//
//  Created by Matthew Watt on 5/5/23.
//

import Generated
import SwiftUI

private enum Constants {
    static let barHeight: CGFloat = 54
}

struct NighthawkTabBar: View {
    @Binding var destination: Home.State.Tab
    let onSelect: (Home.State.Tab) -> Void
    let disableSend: Bool
    
    init(
        destination: Binding<Home.State.Tab>,
        onSelect: @escaping (Home.State.Tab) -> Void,
        disableSend: Bool
    ) {
        self._destination = destination
        self.onSelect = onSelect
        self.disableSend = disableSend
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                title: L10n.Nighthawk.HomeScreen.wallet,
                image: Asset.Assets.Icons.Nighthawk.wallet.image,
                tab: .wallet
            )
            
            tabButton(
                title: L10n.Nighthawk.HomeScreen.transfer,
                image: Asset.Assets.Icons.Nighthawk.transfer.image,
                tab: .transfer,
                isDisabled: disableSend
            )
            
            tabButton(
                title: "Chat",
                image: Image(systemName: "bubble.left.and.bubble.right"),
                tab: .chat
            )
            
            tabButton(
                title: L10n.Nighthawk.HomeScreen.settings,
                image: Asset.Assets.Icons.Nighthawk.settings.image,
                tab: .settings
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.barHeight)
        .background {
            Asset.Colors.Nighthawk.navy.color
                .ignoresSafeArea(edges: .bottom)
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("nighthawk.home.tabbar")
    }
    
    private func tabButton(
        title: String,
        image: Image,
        tab: Home.State.Tab,
        isDisabled: Bool = false
    ) -> some View {
        Button {
            destination = tab
            onSelect(tab)
        } label: {
            TabBarItem(
                title: title,
                image: image,
                isSelected: destination == tab
            )
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(NighthawkTabButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.3 : 1.0)
        .accessibilityIdentifier("nighthawk.home.tab.\(tab)")
    }
}

private struct NighthawkTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct TabBarItem: View {
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

extension NighthawkTabBar {
    static var height: CGFloat { Constants.barHeight }
}
