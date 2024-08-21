//
//  ChangeServerView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents
import ZcashSDKEnvironment

public struct ChangeServerView: View {
    @Bindable var store: StoreOf<ChangeServer>
    
    @FocusState private var isCustomLightwalletdServerEditorFocused: Bool
    
    public var body: some View {
        ScrollView([.vertical], showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.SettingsTab.ChangeServer.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                
                RadioSelectionList(
                    options: ChangeServer.State.LightwalletdOption.allCases,
                    selection: $store.lightwalletdOption.animation(.none)
                ) { option in
                    HStack {
                        if option == .default {
                            Text("Default (\(store.defaultLightwalletdServer))")
                                .paragraphMedium(color: .white)
                        } else {
                            Text("Custom")
                                .paragraphMedium(color: .white)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                
                NighthawkTextField(
                    placeholder: store.defaultLightwalletdServer,
                    text: $store.customLightwalletdServer,
                    isValid: store.validateCustomLightwalletdServer()
                )
                .frame(maxWidth: .infinity)
                .keyboardType(.URL)
                .disabled(store.lightwalletdOption != .custom)
                .opacity(store.lightwalletdOption != .custom ? 0.5 : 1.0)
                .focused($isCustomLightwalletdServerEditorFocused)
                
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
            .padding(.top, 25)
            .padding(.horizontal, 25)
        }
        .onAppear { store.send(.onAppear) }
        .onChange(of: store.lightwalletdOption) { value in
            if value == .custom {
                isCustomLightwalletdServerEditorFocused = true
            }
        }
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
    
    public init(store: StoreOf<ChangeServer>) {
        self.store = store
    }
}

// MARK: - ViewStore
extension StoreOf<ChangeServer> {
    func validateCustomLightwalletdServer() -> NighthawkTextFieldValidationState {
        self.isValidHostAndPort ? .valid : .invalid(error: L10n.Nighthawk.SettingsTab.ChangeServer.Custom.invalidLightwalletd)
    }
}
