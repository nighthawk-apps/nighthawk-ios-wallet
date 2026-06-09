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
                Text(L10n.Nighthawk.SettingsTab.ChangeServer.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                
                RadioSelectionList(
                    options: ChangeServer.State.ServerOption.allCases,
                    selection: $store.serverOption.animation(.none)
                ) { option in
                    HStack {
                        if option == .default {
                            Text("Default (\(store.defaultServerInfo))")
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
                    placeholder: store.defaultServerInfo,
                    text: $store.customServerAddress,
                    isValid: store.validateCustomServer()
                )
                .frame(maxWidth: .infinity)
                .keyboardType(.URL)
                .disabled(store.serverOption != .custom)
                .opacity(store.serverOption != .custom ? 0.5 : 1.0)
                .focused($isCustomServerEditorFocused)
                
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
            "Non-Standard Port",
            isPresented: $store.showPortWarning
        ) {
            Button("Use Anyway", role: .destructive) {
                store.send(.portWarningConfirmed)
            }
            Button("Cancel", role: .cancel) {
                store.send(.portWarningCancelled)
            }
        } message: {
            Text("The port you entered is not a standard DarkFi port (8345 mainnet / 18345 testnet). Using a non-standard port may prevent connection to the network.")
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
