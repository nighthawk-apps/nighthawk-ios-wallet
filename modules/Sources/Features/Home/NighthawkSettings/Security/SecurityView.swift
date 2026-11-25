//
//  SecurityView.swift
//  stealth
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct SecurityView: View {
    @Bindable var store: StoreOf<Security>

    public var body: some View {
        ScrollView([.vertical], showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                biometricsSection

                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.steelBorder.color)

                pinLockSection

                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 25)
            .padding(.bottom, 25)
        }
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }

    public init(store: StoreOf<Security>) {
        self.store = store
    }
}

// MARK: - Private
private extension SecurityView {
    @ViewBuilder
    var biometricsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Nighthawk.SettingsTab.Security.biometricsTitle)
                .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

            if store.hasBiometricsHardware {
                Toggle(isOn: $store.areBiometricsEnabled) {
                    Text(toggleTitle)
                        .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                        .lineSpacing(6)
                }
                .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.Nighthawk.peach.color))
            } else {
                Text(L10n.Nighthawk.SettingsTab.Security.biometricsUnavailable)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
            }
        }
    }

    var pinLockSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Nighthawk.SettingsTab.Security.pinTitle)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                Spacer()
                Text(
                    store.isPinEnabled
                        ? L10n.Nighthawk.SettingsTab.Security.pinEnabled
                        : L10n.Nighthawk.SettingsTab.Security.pinOff
                )
                    .captionBold(
                        color: store.isPinEnabled
                            ? StealthTheme.Colors.statusSuccess
                            : Asset.Colors.Nighthawk.textMuted.color
                    )
            }

            Text(L10n.Nighthawk.SettingsTab.Security.pinDescription)
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)

            if let status = store.pinStatusMessage {
                Text(status)
                    .captionBold(color: StealthTheme.Colors.statusSuccess)
            }

            if store.pinFlowStep != .idle {
                pinEntryCard
            } else if store.isPinEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    Button(L10n.Nighthawk.SettingsTab.Security.pinChange) {
                        store.send(.startChangePinTapped)
                    }
                    .buttonStyle(.nighthawkPrimary())

                    Button(L10n.Nighthawk.SettingsTab.Security.pinVerify) {
                        store.send(.startVerifyPinTapped)
                    }
                    .buttonStyle(.nighthawkSecondary())

                    Button(L10n.Nighthawk.SettingsTab.Security.pinDisable) {
                        store.send(.startDisablePinTapped)
                    }
                    .buttonStyle(
                        .nighthawkPrimary(
                            backgroundColor: StealthTheme.Colors.statusDanger,
                            foregroundColor: StealthTheme.Colors.onDanger
                        )
                    )
                }
            } else {
                Button(L10n.Nighthawk.SettingsTab.Security.pinSet) {
                    store.send(.startSetupPinTapped)
                }
                .buttonStyle(.nighthawkPrimary())
            }
        }
    }

    var pinEntryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.pinPromptTitle)
                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)

            HStack(spacing: 12) {
                ForEach(0..<SecurityPinStore.pinLength, id: \.self) { idx in
                    Circle()
                        .fill(
                            idx < store.pinInput.count
                                ? Asset.Colors.Nighthawk.peach.color
                                : Asset.Colors.Nighthawk.steelBorder.color
                        )
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.vertical, 4)

            SecureField(
                L10n.Nighthawk.Splash.sixDigitPin,
                text: Binding(
                    get: { store.pinInput },
                    set: { store.send(.pinInputChanged($0)) }
                )
            )
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Asset.Colors.Nighthawk.navy.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Asset.Colors.Nighthawk.steelBorder.color, lineWidth: 1)
            )
            .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

            if let error = store.pinErrorMessage {
                Text(error)
                    .caption(color: StealthTheme.Colors.statusDanger)
            }

            HStack(spacing: 12) {
                Button(L10n.Nighthawk.SettingsTab.Security.pinConfirm) {
                    store.send(.submitPinTapped)
                }
                .buttonStyle(.nighthawkPrimary())
                .disabled(store.pinInput.count != SecurityPinStore.pinLength)

                Button(L10n.General.cancel) {
                    store.send(.cancelPinFlowTapped)
                }
                .buttonStyle(.nighthawkSecondary())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Asset.Colors.Nighthawk.navy.color.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Asset.Colors.Nighthawk.steelBorder.color, lineWidth: 1)
        )
    }

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
