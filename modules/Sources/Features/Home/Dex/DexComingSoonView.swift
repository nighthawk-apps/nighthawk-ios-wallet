//
//  DexComingSoonView.swift
//  stealth
//
//  Placeholder matching Android DexComingSoonView / ns_dex_* strings.
//

import Generated
import SwiftUI
import UIComponents

struct DexComingSoonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L10n.Nighthawk.Dex.title.uppercased())
                    .title(color: Asset.Colors.Nighthawk.textHeader.color)
                Spacer()
            }
            .padding(.bottom, 13)

            Text(L10n.Nighthawk.Dex.comingSoon)
                .paragraphMedium(color: Asset.Colors.Nighthawk.textMuted.color)
                .padding(.bottom, 10)

            Text(L10n.Nighthawk.Dex.comingSoonBody)
                .paragraphMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 25)
        .padding(.top, NighthawkLayout.wallpaperWordmarkClearance)
        .padding(.bottom, 25)
        .applyNighthawkBackground()
        .accessibilityIdentifier("nighthawk.dex.comingSoon")
    }
}
