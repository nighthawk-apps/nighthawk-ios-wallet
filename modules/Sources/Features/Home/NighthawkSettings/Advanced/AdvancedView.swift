//
//  AdvancedView.swift
//
//
//  Created by Matthew Watt on 8/3/23.
//

import AlertToast
import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct AdvancedView: View {
    @Bindable var store: StoreOf<Advanced>
    
    public init(store: StoreOf<Advanced>) {
        self.store = store
    }
    
    public var body: some View {
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
                    selection: $store.selectedScreenMode
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
                
                banditSettings
                
                Text(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                
                Text(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.subtitle)
                    .paragraphBold(color: Asset.Colors.Nighthawk.error.color)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                
                Button(L10n.Nighthawk.SettingsTab.Advanced.DeleteWallet.title) {
                    store.send(.deleteWalletTapped)
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
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
}

// MARK: - Subviews
private extension AdvancedView {
    @MainActor 
    @ViewBuilder
    var banditSettings: some View {
        if store.showBanditSettings {
            if store.supportsAlternateIcons {
                Text(L10n.Nighthawk.SettingsTab.Advanced.AppIcon.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                
                RadioSelectionList(
                    options: NighthawkSetting.AppIcon.allCases,
                    selection: $store.selectedAppIcon
                ) { option in
                    HStack(alignment: .center) {
                        option.preview
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.tertiary, lineWidth: 2)
                            )
                        
                        Text(option.label)
                            .paragraphMedium(color: .white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }
            
            Text(L10n.Nighthawk.SettingsTab.Advanced.Theme.title)
                .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
            
            RadioSelectionList(
                options: NighthawkSetting.Theme.allCases,
                selection: $store.theme
            ) { option in
                HStack {
                    switch option {
                    case .`default`:
                        Text(L10n.Nighthawk.SettingsTab.Advanced.Theme.default)
                            .paragraphMedium(color: .white)
                    case .dark:
                        Text(L10n.Nighthawk.SettingsTab.Advanced.Theme.dark)
                            .paragraphMedium(color: .white)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
    }
}
