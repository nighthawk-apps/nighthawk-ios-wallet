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
    @Bindable var store: StoreOf<Fiat>
    let tokenName: String
    
    public var body: some View {
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
                    selection: $store.selectedFiatCurrency.animation(.none)
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
    
    public init(store: StoreOf<Fiat>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
}
