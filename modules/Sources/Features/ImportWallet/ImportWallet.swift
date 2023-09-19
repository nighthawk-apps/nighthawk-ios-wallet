//
//  ImportWallet.swift
//  secant
//
//  Created by Matthew Watt on 5/10/23.
//

import ComposableArchitecture
import Generated
import MnemonicClient
import SwiftUI
import UIComponents
import Utils
import WalletStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct ImportWallet: Reducer {
    let saplingActivationHeight: BlockHeight
    
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        public var birthdayHeight = "".redacted
        public var birthdayHeightValue: RedactableBlockHeight?
        public var importedSeedPhrase = "".redacted
        public var isValidMnemonic = false
        public var wordsCount = 0
        public var isValidNumberOfWords = false
        public var maxWordsCount = 0
        
        public var mnemonicStatus: String {
            if isValidMnemonic {
                return L10n.ImportWallet.Seed.valid
            } else {
                return "\(wordsCount)/\(maxWordsCount)"
            }
        }
        
        public var isValidForm: Bool {
            isValidMnemonic &&
            (birthdayHeight.data.isEmpty ||
            (!birthdayHeight.data.isEmpty && birthdayHeightValue != nil))
        }
                
        public init() {}
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case birthdayInputChanged(RedactableString)
        case continueTapped
        case delegate(Delegate)
        case onAppear
        case seedPhraseInputChanged(RedactableString)
        
        public enum Alert: Equatable {}
        
        public enum Delegate: Equatable {
            case showImportSuccess
        }
    }
    
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public init(saplingActivationHeight: BlockHeight) {
        self.saplingActivationHeight = saplingActivationHeight
    }
    
    public var body: some ReducerOf<ImportWallet> {
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .birthdayInputChanged(let redactedBirthday):
                let saplingActivation = saplingActivationHeight

                state.birthdayHeight = redactedBirthday

                if let birthdayHeight = BlockHeight(state.birthdayHeight.data), birthdayHeight >= saplingActivation {
                    state.birthdayHeightValue = birthdayHeight.redacted
                } else {
                    state.birthdayHeightValue = nil
                }
                return .none
            case .continueTapped:
                do {
                    // validate the seed
                    try mnemonic.isValid(state.importedSeedPhrase.data)
                    
                    // store it to the keychain, if the user did not input a height,
                    // fall back to sapling activation
                    let birthday = state.birthdayHeightValue ?? saplingActivationHeight.redacted
                    
                    try walletStorage.importWallet(state.importedSeedPhrase.data, birthday.data, .english)
                    
                    return .send(.delegate(.showImportSuccess))
                } catch {
                    state.alert = AlertState.importWalletFailed(error.toZcashError())
                    return .none
                }
            case .delegate:
                return .none
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
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}

extension AlertState where Action == ImportWallet.Action.Alert {
    static func importWalletFailed(_ error: ZcashError) -> Self {
        AlertState {
            TextState(L10n.Nighthawk.ImportWallet.Alert.Failed.title)
        } message: {
            TextState(L10n.Nighthawk.ImportWallet.Alert.Failed.message(error.message, error.code.rawValue))
        }
    }
}

extension ViewStoreOf<ImportWallet> {
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
    
    func validateMnemonic() -> NighthawkTextEditor.ValidationState {
        self.isValidMnemonic ? .valid : .invalid(error: L10n.Nighthawk.ImportWallet.invalidMnemonic)
    }
    
    func validateBirthday() -> NighthawkTextFieldValidationState {
        (self.birthdayHeight.data.isEmpty ||
        (!self.birthdayHeight.data.isEmpty && self.birthdayHeightValue != nil))
        ? .valid
        : .invalid(error: L10n.Nighthawk.ImportWallet.invalidBirthday)
    }
}
