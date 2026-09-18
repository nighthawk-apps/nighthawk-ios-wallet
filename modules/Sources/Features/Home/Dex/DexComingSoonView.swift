//
//  DexComingSoonView.swift
//  stealth
//

import Generated
import SwiftUI
import UIComponents

struct DexComingSoonView: View {
    var body: some View {
        VStack(spacing: 16) {
            NighthawkLogo(spacing: .compact, size: .tabHeader)
                .padding(.vertical, 24)

            HStack {
                Text(L10n.Nighthawk.HomeScreen.dex)
                    .paragraphMedium(color: .white)
                Spacer()
            }
            .padding(.horizontal, 25)

            Text(L10n.Nighthawk.DexTab.comingSoon)
                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 25)

            Text(L10n.Nighthawk.DexTab.body)
                .caption()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 25)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .applyNighthawkBackground()
        .accessibilityIdentifier("nighthawk.dex.comingSoon")
    }
}
