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
                            Text(option.label)
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
