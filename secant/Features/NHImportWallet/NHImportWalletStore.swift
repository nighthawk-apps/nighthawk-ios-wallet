//
//  NHImportWalletStore.swift
//  secant
//
//  Created by Matthew Watt on 5/10/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import Utils
import ZcashLightClientKit

struct NHImportWalletReducer: ReducerProtocol {
    struct State: Equatable {
        enum Destination: Equatable {
            case importSuccess
        }
        
        var destination: Destination?
        
        var birthdayHeight = "".redacted
        var birthdayHeightValue: RedactableBlockHeight?
        var importedSeedPhrase = "".redacted
        var isValidMnemonic = false
        var wordsCount = 0
        var isValidNumberOfWords = false
        var maxWordsCount = 0
        
        var mnemonicStatus: String {
            if isValidMnemonic {
                return L10n.ImportWallet.Seed.valid
            } else {
                return "\(wordsCount)/\(maxWordsCount)"
            }
        }
        
        var isValidForm: Bool {
            isValidMnemonic &&
            (birthdayHeight.data.isEmpty ||
            (!birthdayHeight.data.isEmpty && birthdayHeightValue != nil))
        }
        
        var importWalletSuccess: ImportWalletSuccessReducer.State
    }
    
    enum Action: Equatable {
        case birthdayInputChanged(RedactableString)
        case initializeSDK
        case onAppear
        case `continue`
        case seedPhraseInputChanged(RedactableString)
        case successfullyRecovered
        case updateDestination(State.Destination?)
        case importWalletSuccess(ImportWalletSuccessReducer.Action)
    }
    
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    var body: some ReducerProtocol<NHImportWalletReducer.State, NHImportWalletReducer.Action> {
        Scope(state: \.importWalletSuccess, action: /Action.importWalletSuccess) {
            ImportWalletSuccessReducer()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.maxWordsCount = zcashSDKEnvironment.mnemonicWordsMaxCount
                return .none
            case .seedPhraseInputChanged(let redactedSeedPhrase):
                state.importedSeedPhrase = redactedSeedPhrase
                state.wordsCount = state.importedSeedPhrase.data.split(separator: " ").count
                state.isValidNumberOfWords = state.wordsCount == state.maxWordsCount
                // is the mnemonic valid one?
                do {
                    try mnemonic.isValid(state.importedSeedPhrase.data)
                } catch {
                    state.isValidMnemonic = false
                    return .none
                }
                state.isValidMnemonic = true
                return .none
            case .birthdayInputChanged(let redactedBirthday):
                let saplingActivation = TargetConstants.zcashNetwork.constants.saplingActivationHeight

                state.birthdayHeight = redactedBirthday

                if let birthdayHeight = BlockHeight(state.birthdayHeight.data), birthdayHeight >= saplingActivation {
                    state.birthdayHeightValue = birthdayHeight.redacted
                } else {
                    state.birthdayHeightValue = nil
                }
                return .none
            case .continue:
                do {
                    // validate the seed
                    try mnemonic.isValid(state.importedSeedPhrase.data)
                    
                    // store it to the keychain, if the user did not input a height,
                    // fall back to sapling activation
                    let birthday = state.birthdayHeightValue ?? TargetConstants.zcashNetwork.constants.saplingActivationHeight.redacted
                    
                    try walletStorage.importWallet(state.importedSeedPhrase.data, birthday.data, .english, false)
                    
                    // update the backup phrase validation flag
                    try walletStorage.markUserPassedPhraseBackupTest(true)
                    
                    return .concatenate(
                        EffectTask(value: .updateDestination(.importSuccess)),
                        EffectTask(value: .initializeSDK)
                    )
                } catch {
                    // todo: handle error case with whatever android is doing
                    return .none
//                    return EffectTask(value: .alert(.importWallet(.failed(error.localizedDescription))))
                }
            case let .updateDestination(destination):
                state.destination = destination
                return .none
            case .importWalletSuccess, .initializeSDK, .successfullyRecovered:
                return .none
            }
        }
    }
}

// MARK: - Placeholders

extension NHImportWalletReducer.State {
    static let placeholder = NHImportWalletReducer.State(
        importWalletSuccess: .placeholder
    )
}

extension Store<NHImportWalletReducer.State, NHImportWalletReducer.Action> {
    func importSuccessStore() -> Store<ImportWalletSuccessReducer.State, ImportWalletSuccessReducer.Action> {
        self.scope(
            state: \.importWalletSuccess,
            action: NHImportWalletReducer.Action.importWalletSuccess
        )
    }
}

extension ViewStore<NHImportWalletReducer.State, NHImportWalletReducer.Action> {
    func bindingForDestination(_ destination: NHImportWalletReducer.State.Destination) -> Binding<Bool> {
        self.binding(
            get: { $0.destination == destination },
            send: { isActive in
                return .updateDestination(isActive ? destination : nil)
            }
        )
    }
    
    func bindingForRedactableSeedPhrase(_ importedSeedPhrase: RedactableString) -> Binding<String> {
        self.binding(
            get: { _ in importedSeedPhrase.data },
            send: { .seedPhraseInputChanged($0.redacted) }
        )
    }
    
    func bindingForRedactableBirthday(_ birthdayHeight: RedactableString) -> Binding<String> {
        self.binding(
            get: { _ in birthdayHeight.data },
            send: { .birthdayInputChanged($0.redacted) }
        )
    }
    
    func validateMnemonic() -> NHTextEditor.ValidationState {
        self.isValidMnemonic ? .valid : .invalid(error: L10n.Nighthawk.ImportWallet.invalidMnemonic)
    }
    
    func validateBirthday() -> NHTextField.ValidationState {
        (self.birthdayHeight.data.isEmpty ||
        (!self.birthdayHeight.data.isEmpty && self.birthdayHeightValue != nil))
        ? .valid
        : .invalid(error: L10n.Nighthawk.ImportWallet.invalidBirthday)
    }
}
