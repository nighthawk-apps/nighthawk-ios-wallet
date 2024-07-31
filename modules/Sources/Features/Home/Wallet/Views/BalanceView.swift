//
//  BalanceView.swift
//  secant
//
//  Created by Matthew Watt on 5/6/23.
//

import Generated
import SwiftUI
import ZcashLightClientKit

public struct BalanceView: View {
    public enum ViewType: Equatable, Hashable, CaseIterable {
        case hidden
        case total
        case shielded
        case transparent
    }
    
    let balance: Zatoshi
    let type: ViewType
    let tokenName: String
    let synchronizerState: SynchronizerState
    
    public init(balance: Zatoshi, type: ViewType, tokenName: String, synchronizerState: SynchronizerState) {
        self.balance = balance
        self.type = type
        self.tokenName = tokenName
        self.synchronizerState = synchronizerState
    }
    
    var isBalanceHidden: Bool {
        if case .hidden = type {
            return true
        }
        
        return false
    }
    
    public var body: some View {
        VStack {
            balanceImage(for: type)
                .resizable()
                .frame(width: 24, height: 24)
                .padding(.bottom, 20)
            
            if !isBalanceHidden {
                VStack {
                    // swift-lint:disable:next-line line_length
                    Text(
                        "\(balance.decimalString()) \(Text(tokenName).foregroundColor(Asset.Colors.Nighthawk.peach.color))"
                    )
                    
                    expectingFundsText(for: synchronizerState, type: type)
                }
                .foregroundColor(.white)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 28))
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
    
    func expectingFundsText(for state: SynchronizerState, type: ViewType) -> some View {
        var expectingFundsString: String?
        switch type {
        case .hidden, .transparent:
            break
        case .shielded:
            let totalBalance = (state.accountBalance?.orchardBalance.total() ?? .zero) +
                (state.accountBalance?.saplingBalance.total() ?? .zero)
            let availableBalance = (state.accountBalance?.orchardBalance.spendableValue ?? .zero) +
                (state.accountBalance?.saplingBalance.spendableValue ?? .zero)
            if totalBalance > availableBalance {
                expectingFundsString = L10n.Nighthawk.HomeScreen.expectingFunds(
                    (totalBalance - availableBalance).decimalString(),
                    tokenName
                )
            }
        case .total:
            let totalBalance = (state.accountBalance?.orchardBalance.total() ?? .zero) +
                (state.accountBalance?.saplingBalance.total() ?? .zero) +
                (state.accountBalance?.unshielded ?? .zero)
            let availableBalance = (state.accountBalance?.orchardBalance.spendableValue ?? .zero) +
                (state.accountBalance?.saplingBalance.spendableValue ?? .zero) +
                (state.accountBalance?.unshielded ?? .zero)
            if totalBalance > availableBalance {
                expectingFundsString = L10n.Nighthawk.HomeScreen.expectingFunds(
                    (totalBalance - availableBalance).decimalString(),
                    tokenName
                )
            }
        }
        
        return Group {
            if let expectingFundsString {
                Text(expectingFundsString)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
            }
        }
    }
}
