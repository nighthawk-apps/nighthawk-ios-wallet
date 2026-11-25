//
//  ChangeServerView.swift
//  stealth
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct ChangeServerView: View {
    @Bindable var store: StoreOf<ChangeServer>

    @FocusState private var isCustomServerEditorFocused: Bool

    public var body: some View {
        ScrollView([.vertical], showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                RadioSelectionList(
                    options: ChangeServer.State.ServerOption.allCases,
                    selection: $store.serverOption.animation(.none)
                ) { option in
                    HStack {
                        if option == .default {
                            Text(L10n.Nighthawk.SettingsTab.ChangeServer.default(store.defaultServerInfo))
                                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                        } else {
                            Text(L10n.Nighthawk.SettingsTab.ChangeServer.custom)
                                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 12)
                }

                NighthawkTextField(
                    placeholder: L10n.Nighthawk.SettingsTab.ChangeServer.placeholder,
                    text: $store.customServerAddress,
                    isValid: store.validateCustomServer()
                )
                .frame(maxWidth: .infinity)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(store.serverOption != .custom)
                .opacity(store.serverOption != .custom ? 0.5 : 1.0)
                .focused($isCustomServerEditorFocused)

                Toggle(
                    isOn: Binding(
                        get: { store.useTls },
                        set: { store.send(.useTlsToggled($0)) }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Nighthawk.SettingsTab.ChangeServer.useTlsTitle)
                            .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                        Text(L10n.Nighthawk.SettingsTab.ChangeServer.useTlsSubtitle)
                            .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.Nighthawk.peach.color))
                .disabled(store.serverOption != .custom)
                .opacity(store.serverOption != .custom ? 0.5 : 1.0)

                presetsSection

                VStack(alignment: .center) {
                    Button(
                        L10n.Nighthawk.SettingsTab.ChangeServer.save,
                        action: { store.send(.saveTapped) }
                    )
                    .buttonStyle(.nighthawkPrimary(width: 156))
                    .disabled(!store.canSave)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)

                Text(L10n.Nighthawk.SettingsTab.ChangeServer.disclaimer)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)

                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 25)
        }
        .onAppear { store.send(.onAppear) }
        .onChange(of: store.serverOption) {
            if store.serverOption == .custom {
                isCustomServerEditorFocused = true
            }
        }
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
        .alert(
            L10n.Nighthawk.SettingsTab.ChangeServer.portWarningTitle,
            isPresented: $store.showPortWarning
        ) {
            Button(L10n.Nighthawk.SettingsTab.ChangeServer.portWarningUseAnyway, role: .destructive) {
                store.send(.portWarningConfirmed)
            }
            Button(L10n.General.cancel, role: .cancel) {
                store.send(.portWarningCancelled)
            }
        } message: {
            Text(L10n.Nighthawk.SettingsTab.ChangeServer.portWarningMessage)
        }
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Nighthawk.SettingsTab.ChangeServer.presets)
                .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)

            ForEach(store.presets) { preset in
                Button {
                    store.send(.presetSelected(preset))
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.title)
                                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                            Text(preset.subtitle)
                                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        if store.serverOption == .custom && store.effectiveCustomEndpoint == preset.endpoint {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Asset.Colors.Nighthawk.navy.color.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Asset.Colors.Nighthawk.steelBorder.color, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    public init(store: StoreOf<ChangeServer>) {
        self.store = store
    }
}

// MARK: - ViewStore
extension StoreOf<ChangeServer> {
    func validateCustomServer() -> NighthawkTextFieldValidationState {
        self.isValidHostAndPort ? .valid : .invalid(error: L10n.Nighthawk.SettingsTab.ChangeServer.Custom.invalidLightwalletd)
    }
}
