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
    let store: StoreOf<ChangeServer>
    
    @FocusState private var isCustomLightwalletdServerEditorFocused: Bool
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView([.vertical], showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Nighthawk.SettingsTab.ChangeServer.title)
                        .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    RadioSelectionList(
                        options: ChangeServer.State.LightwalletdOption.allCases,
                        selection: viewStore.$lightwalletdOption.animation(.none)
                    ) { option in
                        HStack {
                            if option == .default {
                                Text("Default (\(viewStore.defaultLightwalletdServer))")
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
                        placeholder: viewStore.defaultLightwalletdServer,
                        text: viewStore.$customLightwalletdServer,
                        isValid: viewStore.validateCustomLightwalletdServer()
                    )
                    .frame(maxWidth: .infinity)
                    .keyboardType(.URL)
                    .disabled(viewStore.lightwalletdOption != .custom)
                    .opacity(viewStore.lightwalletdOption != .custom ? 0.5 : 1.0)
                    .focused($isCustomLightwalletdServerEditorFocused)
                    
                    VStack(alignment: .center) {
                        Button(
                            L10n.Nighthawk.SettingsTab.ChangeServer.save,
                            action: { viewStore.send(.saveTapped) }
                        )
                        .buttonStyle(.nighthawkPrimary(width: 156))
                        .disabled(!viewStore.canSave)
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
            .onAppear { viewStore.send(.onAppear) }
            .onChange(of: viewStore.lightwalletdOption) { value in
                if value == .custom {
                    isCustomLightwalletdServerEditorFocused = true
                }
            }
        }
        .applyNighthawkBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
    
    public init(store: StoreOf<ChangeServer>) {
        self.store = store
    }
}

// MARK: - ViewStore
extension ViewStoreOf<ChangeServer> {
    func validateCustomLightwalletdServer() -> NighthawkTextFieldValidationState {
        self.isValidHostAndPort ? .valid : .invalid(error: L10n.Nighthawk.SettingsTab.ChangeServer.Custom.invalidLightwalletd)
    }
}
