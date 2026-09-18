//
//  AssetPortfolioView.swift
//  stealth
//

import Generated
import SDKSynchronizer
import SwiftUI
import UIComponents
import Utils

/// Asset list for Wallet home. DRK is always the first row.
struct AssetPortfolioView: View {
    let rows: [TokenBalanceInfo]
    let onTokenTap: (TokenBalanceInfo) -> Void

    var body: some View {
        NighthawkHudPanel {
            Text(L10n.Nighthawk.WalletTab.assetsTitle)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                .foregroundColor(.white)
            ForEach(rows) { token in
                Button {
                    onTokenTap(token)
                } label: {
                    HStack {
                        Text(token.displayName)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                            .foregroundColor(.white)
                        Spacer()
                        Text(token.balanceFormatted)
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 15))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("nighthawk.wallet.asset.\(token.tokenId)")
            }
        }
        .padding(.horizontal, 16)
    }
}
