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
        @BindingState public var importedSeedPhrase = ""
        @BindingState public var birthdayHeight = ""
        public var birthdayHeightValue: RedactableBlockHeight?
        public var isValidMnemonic = false
        public var wordsCount = 0
        public var isValidNumberOfWords = false
        public var maxWordsCount = 0
        public var isValidForm: Bool {
            isValidMnemonic &&
            (birthdayHeight.isEmpty ||
            (!birthdayHeight.isEmpty && birthdayHeightValue != nil))
        }
                
        public init() {
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            maxWordsCount = zcashSDKEnvironment.mnemonicWordsMaxCount
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case continueTapped
        case delegate(Delegate)
        
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
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .binding(\.$birthdayHeight):
                let saplingActivation = saplingActivationHeight
                if let birthdayHeight = BlockHeight(state.birthdayHeight), birthdayHeight >= saplingActivation {
                    state.birthdayHeightValue = birthdayHeight.redacted
                } else {
                    state.birthdayHeightValue = nil
                }
                return .none
            case .binding(\.$importedSeedPhrase):
                let trimmedPhraseWords = state.importedSeedPhrase.split(separator: " ")
                    .filter { !$0.isEmpty }
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                state.wordsCount = trimmedPhraseWords.count
                state.isValidNumberOfWords = state.wordsCount == state.maxWordsCount
                // is the mnemonic valid one?
                do {
                    try mnemonic.isValid(trimmedPhraseWords.joined(separator: " "))
                } catch {
                    state.isValidMnemonic = false
                    return .none
                }
                state.isValidMnemonic = true
                return .none
            case .binding:
                return .none
            case .continueTapped:
                do {
                    let trimmedPhraseWords = state.importedSeedPhrase.split(separator: " ")
                        .filter { !$0.isEmpty }
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    
                    // validate the seed
                    let cleanedPhrase = trimmedPhraseWords.joined(separator: " ")
                    try mnemonic.isValid(cleanedPhrase)
                    
                    // store it to the keychain, if the user did not input a height,
                    // fall back to sapling activation
                    let birthday = state.birthdayHeightValue ?? saplingActivationHeight.redacted
                    
                    try walletStorage.importWallet(cleanedPhrase, birthday.data, .english)
                    
                    return .send(.delegate(.showImportSuccess))
                } catch {
                    state.alert = AlertState.importWalletFailed(error.toZcashError())
                    return .none
                }
            case .delegate:
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
    func validateMnemonic() -> NighthawkTextEditor.ValidationState {
        self.isValidMnemonic ? .valid : .invalid(error: L10n.Nighthawk.ImportWallet.invalidMnemonic)
    }
    
    func validateBirthday() -> NighthawkTextFieldValidationState {
        (self.birthdayHeight.isEmpty ||
        (!self.birthdayHeight.isEmpty && self.birthdayHeightValue != nil))
        ? .valid
        : .invalid(error: L10n.Nighthawk.ImportWallet.invalidBirthday)
    }
}
