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
                            switch option {
                            case .usd:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.usd)
                                    .paragraphMedium(color: .white)
                            case .eur:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.eur)
                                    .paragraphMedium(color: .white)
                            case .inr:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.inr)
                                    .paragraphMedium(color: .white)
                            case .jpy:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.jpy)
                                    .paragraphMedium(color: .white)
                            case .gbp:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.gbp)
                                    .paragraphMedium(color: .white)
                            case .cad:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.cad)
                                    .paragraphMedium(color: .white)
                            case .aud:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.aud)
                                    .paragraphMedium(color: .white)
                            case .hkd:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.hkd)
                                    .paragraphMedium(color: .white)
                            case .sgd:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.sgd)
                                    .paragraphMedium(color: .white)
                            case .chf:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.chf)
                                    .paragraphMedium(color: .white)
                            case .cny:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.cny)
                                    .paragraphMedium(color: .white)
                            case .krw:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.krw)
                                    .paragraphMedium(color: .white)
                            case .off:
                                Text(L10n.Nighthawk.SettingsTab.FiatCurrency.off)
                                    .paragraphMedium(color: .white)
                            }
                            
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
