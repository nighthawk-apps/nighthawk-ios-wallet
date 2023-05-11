//
//  BalanceView.swift
//  secant
//
//  Created by Matthew Watt on 5/6/23.
//

import SwiftUI
import ZcashLightClientKit

struct BalanceView: View {
    enum ViewType: Equatable, Hashable, CaseIterable {
        case hidden
        case total
        case shielded
        case transparent
    }
    
    let balance: Zatoshi
    let type: ViewType
    
    var isBalanceHidden: Bool {
        if case .hidden = type {
            return true
        }
        
        return false
    }
    
    var body: some View {
        VStack {
            balanceImage(for: type)
                .resizable()
                .frame(width: 24, height: 24)
                .padding(.bottom, 20)
            
            if !isBalanceHidden {
                // swift-lint:disable:next-line line_length
                Text(
                    "\(balance.decimalString(formatter: NumberFormatter.zcashNumberFormatter8FractionDigits)) \(Text(TargetConstants.tokenName).foregroundColor(Asset.Colors.Nighthawk.peach.color))"
                )
                .foregroundColor(.white)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 28))
                .padding(.bottom, 5)
            }
            
            balanceText(for: type)
        }
    }
}

// MARK: - Subviews
private extension BalanceView {
    func balanceImage(for type: ViewType) -> Image {
        switch type {
        case .hidden:
            return Asset.Assets.Icons.Nighthawk.swipe.image
        case .total:
            return Asset.Assets.Icons.Nighthawk.piggy.image
        case .shielded:
            return Asset.Assets.Icons.Nighthawk.shielded.image
        case .transparent:
            return Asset.Assets.Icons.Nighthawk.unshielded.image
        }
    }
    
    func balanceText(for type: ViewType) -> some View {
        let balanceString: String
        switch type {
        case .hidden:
            balanceString = L10n.Nighthawk.WalletTab.swipeToShowBalances
        case .total:
            balanceString = L10n.Nighthawk.WalletTab.totalBalance
        case .shielded:
            balanceString = L10n.Nighthawk.WalletTab.shieldedBalance
        case .transparent:
            balanceString = L10n.Nighthawk.WalletTab.transparentBalance
        }
        
        return Text(balanceString)
            .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
    }
}
