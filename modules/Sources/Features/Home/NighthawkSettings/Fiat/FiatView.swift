//
//  FiatView.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct FiatView: View {
    let store: StoreOf<Fiat>
    let tokenName: String
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView([.vertical], showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Nighthawk.SettingsTab.FiatCurrency.title)
                        .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    Text(L10n.Nighthawk.SettingsTab.FiatCurrency.description(tokenName))
                        .paragraphMedium(color: .white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                    
                    RadioSelectionList(
                        options: NighthawkSetting.FiatCurrency.allCases,
                        selection: viewStore.$selectedFiatCurrency.animation(.none)
                    ) { option in
                        HStack {
                            Text(label(for: option))
                                .paragraphMedium(color: .white)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    
                    Spacer()
                }
                .padding(.top, 25)
                .padding(.horizontal, 25)
            }
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<Fiat>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
}

// MARK: - Private
private extension FiatView {
    func label(for fiat: NighthawkSetting.FiatCurrency) -> String {
        switch fiat {
        case .usd:
            L10n.Nighthawk.SettingsTab.FiatCurrency.usd
        case .eur:
            L10n.Nighthawk.SettingsTab.FiatCurrency.eur
        case .inr:
            L10n.Nighthawk.SettingsTab.FiatCurrency.inr
        case .jpy:
            L10n.Nighthawk.SettingsTab.FiatCurrency.jpy
        case .gbp:
            L10n.Nighthawk.SettingsTab.FiatCurrency.gbp
        case .cad:
            L10n.Nighthawk.SettingsTab.FiatCurrency.cad
        case .aud:
            L10n.Nighthawk.SettingsTab.FiatCurrency.aud
        case .hkd:
            L10n.Nighthawk.SettingsTab.FiatCurrency.hkd
        case .sgd:
            L10n.Nighthawk.SettingsTab.FiatCurrency.sgd
        case .chf:
            L10n.Nighthawk.SettingsTab.FiatCurrency.chf
        case .cny:
            L10n.Nighthawk.SettingsTab.FiatCurrency.cny
        case .krw:
            L10n.Nighthawk.SettingsTab.FiatCurrency.krw
        case .off:
            L10n.Nighthawk.SettingsTab.FiatCurrency.off
        }
    }
}
