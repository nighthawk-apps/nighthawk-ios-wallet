//
//  NHImportWalletView.swift
//  secant
//
//  Created by Matthew Watt on 5/10/23.
//

import ComposableArchitecture
import Generated
import SwiftUI

struct NHImportWalletView: View {
    let store: Store<NHImportWalletReducer.State, NHImportWalletReducer.Action>
    
    @FocusState private var isSeedEditorFocused: Bool
    @FocusState private var isBirthdayEditorFocused: Bool
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 24) {
                VStack(spacing: 24) {
                    NighthawkLogo(spacing: .compact)
                    
                    instructions()
                }
                .onTapGesture {
                    isSeedEditorFocused = false
                    isBirthdayEditorFocused = false
                }
                
                NHTextEditor(
                    placeholder: L10n.Nighthawk.ImportWallet.yourSeedPhrase,
                    text: viewStore.bindingForRedactableSeedPhrase(viewStore.importedSeedPhrase),
                    isValid: viewStore.validateMnemonic()
                )
                .frame(width: nil, height: 120, alignment: .center)
                .padding(.horizontal, 24)
                .focused($isSeedEditorFocused)
                
                NHTextField(
                    placeholder: L10n.Nighthawk.ImportWallet.birthdayHeight,
                    text: viewStore.bindingForRedactableBirthday(viewStore.birthdayHeight),
                    isValid: viewStore.validateBirthday()
                )
                .frame(maxWidth: .infinity)
                .keyboardType(.numberPad)
                .padding(.horizontal, 24)
                .focused($isBirthdayEditorFocused)
                
                Button(L10n.Nighthawk.ImportWallet.continue) {
                    viewStore.send(.continue)
                }
                .buttonStyle(.nighthawkPrimary(width: 156))
                .disabled(!viewStore.state.isValidForm)
                
                Spacer()
            }
            .applyNighthawkBackground()
            .scrollableWhenScaledUp()
            .onAppear {
                viewStore.send(.onAppear)
                isSeedEditorFocused = true
            }
            .navigationLinkEmpty(isActive: viewStore.bindingForDestination(.importSuccess)) {
                ImportWalletSuccessView(
                    store: store.importSuccessStore()
                )
            }
        }
    }
}

// MARK: - Subviews
private extension NHImportWalletView {
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
