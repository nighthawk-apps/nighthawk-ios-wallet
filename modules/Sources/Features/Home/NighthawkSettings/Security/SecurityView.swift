//
//  SecurityView.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct SecurityView: View {
    @Bindable var store: StoreOf<Security>
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Nighthawk.SettingsTab.securityTitle)
                .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
            
            Toggle(
                toggleTitle,
                isOn: $store.areBiometricsEnabled
            )
            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
            .foregroundColor(.white)
            .lineSpacing(6)
            .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.Nighthawk.peach.color))
            
            Spacer()
        }
        .padding(.top, 25)
        .padding(.horizontal, 25)
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<Security>) {
        self.store = store
    }
}

// MARK: - Private
private extension SecurityView {
    var toggleTitle: String {
        switch store.biometryType {
        case .faceID:
            return store.areBiometricsEnabled
                ? L10n.Nighthawk.SettingsTab.Security.biometricsEnabled("Face ID")
                : L10n.Nighthawk.SettingsTab.Security.biometricsDisabled("Face ID")
        case .touchID:
            return store.areBiometricsEnabled
                ? L10n.Nighthawk.SettingsTab.Security.biometricsEnabled("Touch ID")
                : L10n.Nighthawk.SettingsTab.Security.biometricsDisabled("Touch ID")
        case .none, .opticID:
            return ""
        @unknown default:
            return ""
        }
    }
}
