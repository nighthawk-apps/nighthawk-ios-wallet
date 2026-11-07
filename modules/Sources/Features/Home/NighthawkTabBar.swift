//
//  NighthawkTabBar.swift
//  stealth
//
//  Created by Matthew Watt on 5/5/23.
//

import Generated
import Models
import SwiftUI
import UIComponents

private enum Constants {
    static let barHeight: CGFloat = 54
}

enum NighthawkTabPlacement {
    /// Phone / folded width — icons along the bottom.
    case bottomBar
    /// Expanded / Duo width — icons in a leading rail (Android NavigationRail).
    case leadingRail
}

struct NighthawkTabBar: View {
    let selectedTab: Home.State.Tab
    let onSelect: (Home.State.Tab) -> Void
    let disableSend: Bool
    var placement: NighthawkTabPlacement = .bottomBar
    @ObservedObject private var themes = NighthawkThemeController.shared

    init(
        selectedTab: Home.State.Tab,
        onSelect: @escaping (Home.State.Tab) -> Void,
        disableSend: Bool,
        placement: NighthawkTabPlacement = .bottomBar
    ) {
        self.selectedTab = selectedTab
        self.onSelect = onSelect
        self.disableSend = disableSend
        self.placement = placement
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        Group {
            switch placement {
            case .bottomBar:
                bottomBar
            case .leadingRail:
                leadingRail
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("nighthawk.home.tabbar")
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabButtons
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.barHeight)
        .background { chromeBackground.ignoresSafeArea(edges: .bottom) }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var leadingRail: some View {
        // Pad outside the chrome so the wallpaper wordmark stays visible (Android rail parity).
        VStack(spacing: 4) {
            tabButtons
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { chromeBackground }
        .padding(.top, NighthawkLayout.wallpaperWordmarkClearance)
    }

    @ViewBuilder
    private var tabButtons: some View {
        tabButton(
            title: "Chat",
            image: Image(systemName: "bubble.left.and.bubble.right"),
            tab: .chat
        )
        tabButton(
            title: L10n.Nighthawk.HomeScreen.wallet,
            image: Asset.Assets.Icons.Nighthawk.wallet.image,
            tab: .wallet
        )
        tabButton(
            title: L10n.Nighthawk.HomeScreen.dex,
            image: Asset.Assets.Icons.Nighthawk.transfer.image,
            tab: .dex
        )
        tabButton(
            title: L10n.Nighthawk.DaoHub.title,
            // SF Symbol "person.3" — DAO Hub metaphor (open Apple SF Symbols).
            image: Image(systemName: "person.3"),
            tab: .daoHub
        )
        tabButton(
            title: L10n.Nighthawk.HomeScreen.settings,
            image: Asset.Assets.Icons.Nighthawk.settings.image,
            tab: .settings
        )
    }

    private var chromeBackground: some View {
        Group {
            if themes.theme.usesCyberpunkChrome {
                Color(red: 0x05 / 255, green: 0x08 / 255, blue: 0x10 / 255, opacity: 0.85)
            } else {
                Asset.Colors.Nighthawk.navy.color
            }
        }
    }

    private func tabButton(
        title: String,
        image: Image,
        tab: Home.State.Tab,
        isDisabled: Bool = false
    ) -> some View {
        TabBarItem(
            title: title,
            image: image,
            isSelected: selectedTab == tab,
            placement: placement
        )
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(title)
        .opacity(isDisabled ? 0.3 : 1.0)
        .onTapGesture {
            guard !isDisabled else { return }
            onSelect(tab)
        }
        .accessibilityIdentifier("nighthawk.home.tab.\(tab)")
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
}

private struct TabBarItem: View {
    let title: String
    let image: Image
    let isSelected: Bool
    let placement: NighthawkTabPlacement

    var body: some View {
        VStack {
            image
                .resizable()
                .renderingMode(.template).scaledToFit()
                .foregroundColor(
                    isSelected
                        ? Asset.Colors.Nighthawk.peach.color
                        : Asset.Colors.Nighthawk.textHeader.color
                )
                .frame(width: 24, height: 24)
            Text(title)
                .caption(
                    color: isSelected
                        ? Asset.Colors.Nighthawk.peach.color
                        : Asset.Colors.Nighthawk.textHeader.color
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, placement == .bottomBar ? 8 : 10)
        .padding(.bottom, placement == .bottomBar ? 4 : 8)
        .overlay(alignment: placement == .bottomBar ? .top : .leading) {
            Rectangle()
                .fill(
                    isSelected
                        ? Asset.Colors.Nighthawk.peach.color
                        : .clear
                )
                .frame(
                    width: placement == .leadingRail ? 4 : nil,
                    height: placement == .bottomBar ? 4 : nil
                )
                .frame(
                    maxWidth: placement == .bottomBar ? .infinity : nil,
                    maxHeight: placement == .leadingRail ? .infinity : nil
                )
                .allowsHitTesting(false)
        }
    }
}

extension NighthawkTabBar {
    static var height: CGFloat { Constants.barHeight }
}
