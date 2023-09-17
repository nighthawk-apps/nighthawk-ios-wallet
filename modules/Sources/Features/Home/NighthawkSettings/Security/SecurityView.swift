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
    var store: StoreOf<Security>
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.SettingsTab.securityTitle)
                    .paragraphMedium()
                
                Toggle(
                    toggleTitle(with: viewStore),
                    isOn: viewStore.$areBiometricsEnabled
                )
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                .lineSpacing(6)
                .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.Nighthawk.peach.color))
                
                Spacer()
            }
            .padding(.top, 25)
            .padding(.horizontal, 25)
            .onAppear { viewStore.send(.onAppear) }
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<Security>) {
        self.store = store
    }
}

// MARK: - Private
private extension SecurityView {
    func toggleTitle(with viewStore: ViewStoreOf<Security>) -> String {
        switch viewStore.biometryType {
        case .faceID:
            return viewStore.areBiometricsEnabled
                ? L10n.Nighthawk.SettingsTab.Security.biometricsEnabled("Face ID")
                : L10n.Nighthawk.SettingsTab.Security.biometricsDisabled("Face ID")
        case .touchID:
            return viewStore.areBiometricsEnabled
                ? L10n.Nighthawk.SettingsTab.Security.biometricsEnabled("Touch ID")
                : L10n.Nighthawk.SettingsTab.Security.biometricsDisabled("Touch ID")
        case .none:
            return ""
        @unknown default:
            return ""
        }
    }
}
