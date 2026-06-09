//
//  BalanceView.swift
//  stealth
//
//  Created by Matthew Watt on 5/6/23.
//

import Generated
import SwiftUI
import Utils

public struct BalanceView: View {
    public enum ViewType: Equatable, Hashable, CaseIterable {
        case hidden
        case total
    }
    
    let balance: DrkAmount
    let type: ViewType
    let tokenName: String
    let synchronizerState: SynchronizerState
    
    public init(balance: DrkAmount, type: ViewType, tokenName: String, synchronizerState: SynchronizerState) {
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
                    Text(
                        "\(balance.decimalString()) \(Text(tokenName).foregroundColor(Asset.Colors.Nighthawk.peach.color))"
                    )
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
        }
    }
    
    func balanceText(for type: ViewType) -> some View {
        let balanceString: String
        switch type {
        case .hidden:
            balanceString = L10n.Nighthawk.WalletTab.swipeToShowBalances
        case .total:
            balanceString = L10n.Nighthawk.WalletTab.totalBalance
        }
        
        return Text(balanceString)
            .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
    }
}
