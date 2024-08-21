//
//  ExternalServicesView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct ExternalServicesView: View {
    @Bindable var store: StoreOf<ExternalServices>
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Nighthawk.SettingsTab.ExternalServices.title)
                .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
            
            Toggle(
                L10n.Nighthawk.SettingsTab.ExternalServices.unstoppableDomainsToggle,
                isOn: $store.isUnstoppableDomainsEnabled
            )
            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
            .lineSpacing(6)
            .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.Nighthawk.peach.color))
            
            Spacer()
        }
        .padding(.top, 25)
        .padding(.horizontal, 25)
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<ExternalServices>) {
        self.store = store
    }
}
