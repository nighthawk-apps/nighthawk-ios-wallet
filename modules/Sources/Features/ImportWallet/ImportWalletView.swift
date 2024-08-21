//
//  ImportWalletView.swift
//  secant
//
//  Created by Matthew Watt on 5/10/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct ImportWalletView: View {
    @Bindable var store: StoreOf<ImportWallet>
    
    @FocusState private var isSeedEditorFocused: Bool
    @FocusState private var isBirthdayEditorFocused: Bool
    
    public init(store: StoreOf<ImportWallet>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 24) {
                NighthawkLogo(spacing: .compact)
                
                instructions()
            }
            .onTapGesture {
                isSeedEditorFocused = false
                isBirthdayEditorFocused = false
            }
            
            NighthawkTextEditor(
                placeholder: L10n.Nighthawk.ImportWallet.yourSeedPhrase,
                text: $store.importedSeedPhrase,
                isValid: store.validateMnemonic()
            )
            .frame(width: nil, height: 120, alignment: .center)
            .padding(.horizontal, 24)
            .focused($isSeedEditorFocused)
            
            NighthawkTextField(
                placeholder: L10n.Nighthawk.ImportWallet.birthdayHeight,
                text: $store.birthdayHeight,
                isValid: store.validateBirthday()
            )
            .frame(maxWidth: .infinity)
            .keyboardType(.numberPad)
            .padding(.horizontal, 24)
            .focused($isBirthdayEditorFocused)
            
            Button(L10n.Nighthawk.ImportWallet.continue) {
                store.send(.continueTapped)
            }
            .buttonStyle(.nighthawkPrimary(width: 156))
            .disabled(!store.state.isValidForm)
            
            Spacer()
        }
        .applyNighthawkBackground()
        .scrollableWhenScaledUp()
        .onAppear {
            isSeedEditorFocused = true
        }
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
}

// MARK: - Subviews
private extension ImportWalletView {
    @ViewBuilder func instructions() -> some View {
        Text(L10n.Nighthawk.ImportWallet.restoreFromBackup)
            .subtitle()
        
        Text(L10n.Nighthawk.ImportWallet.enterSeedPhrase)
            .paragraph()
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(10)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 58)
    }
}

// MARK: - ViewStore
extension StoreOf<ImportWallet> {
    func validateMnemonic() -> NighthawkTextEditor.ValidationState {
        self.isValidMnemonic ? .valid : .invalid(error: L10n.Nighthawk.ImportWallet.invalidMnemonic)
    }
    
    func validateBirthday() -> NighthawkTextFieldValidationState {
        self.isValidBirthday ? .valid : .invalid(error: L10n.Nighthawk.ImportWallet.invalidBirthday)
    }
}
