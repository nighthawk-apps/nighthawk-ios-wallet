//
//  AdvancedView.swift
//  
//
//  Created by Matthew Watt on 8/3/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct AdvancedView: View {
    let store: StoreOf<Advanced>
    
    public init(store: StoreOf<Advanced>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView([.vertical], showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Nighthawk.SettingsTab.advancedTitle)
                        .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    Text(L10n.Nighthawk.SettingsTab.Advanced.ScreenMode.title)
                        .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    Text(L10n.Nighthawk.SettingsTab.Advanced.ScreenMode.subtitle)
                        .paragraphMedium(color: .white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                    
                    
                    RadioSelectionList(
                        options: NighthawkSetting.ScreenMode.allCases,
                        selection: viewStore.$selectedScreenMode
                    ) { option in
                        HStack {
                            switch option {
                            case .keepOn:
                                Text(L10n.Nighthawk.SettingsTab.Advanced.ScreenMode.keepOn)
                                    .paragraphMedium(color: .white)
                            case .off:
                                Text(L10n.Nighthawk.SettingsTab.Advanced.ScreenMode.off)
                                    .paragraphMedium(color: .white)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    
                    Text(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.title)
                        .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    Text(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.subtitle)
                        .paragraphBold(color: Asset.Colors.Nighthawk.error.color)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                    
                    Button(L10n.Nighthawk.SettingsTab.Advanced.NukeWallet.title) {
                        viewStore.send(.nukeWalletTapped)
                    }
                    .buttonStyle(
                        .nighthawkPrimary(
                            backgroundColor: Asset.Colors.Nighthawk.error.color,
                            foregroundColor: .white
                        )
                    )
                }
                .padding(.vertical, 25)
            }
            .padding(.horizontal, 25)
            .onAppear { viewStore.send(.onAppear) }
        }
        .applyNighthawkBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
}
