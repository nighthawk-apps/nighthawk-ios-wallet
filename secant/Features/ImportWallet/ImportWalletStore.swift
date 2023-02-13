//
//  ImportWalletStore.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 02/25/2022.
//

import ComposableArchitecture
import ZcashLightClientKit
import SwiftUI

typealias ImportWalletStore = Store<ImportWalletReducer.State, ImportWalletReducer.Action>
typealias ImportWalletViewStore = ViewStore<ImportWalletReducer.State, ImportWalletReducer.Action>

struct ImportWalletReducer: ReducerProtocol {
    struct State: Equatable {
        @BindingState var alert: AlertState<ImportWalletReducer.Action>?
        var birthdayHeight = "".redacted
        var birthdayHeightValue: RedactableBlockHeight?
        var importedSeedPhrase = "".redacted
        var isValidMnemonic = false
        var isValidNumberOfWords = false
        var maxWordsCount = 0
        var wordsCount = 0
        
        var mnemonicStatus: String {
            if isValidMnemonic {
                return "VALID SEED PHRASE"
            } else {
                return "\(wordsCount)/\(maxWordsCount)"
            }
        }
        
        var isValidForm: Bool {
            isValidMnemonic &&
            (birthdayHeight.data.isEmpty ||
            (!birthdayHeight.data.isEmpty && birthdayHeightValue != nil))
        }
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<ImportWalletReducer.State>)
        case birthdayInputChanged(RedactableString)
        case dismissAlert
        case restoreWallet
        case importPrivateOrViewingKey
        case initializeSDK
        case onAppear
        case seedPhraseInputChanged(RedactableString)
        case successfullyRecovered
    }

    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment

    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
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
                state.birthdayHeight = redactedBirthday
                if let birthdayHeight = BlockHeight(state.birthdayHeight.data), birthdayHeight >= zcashSDKEnvironment.defaultBirthday {
                    state.birthdayHeightValue = birthdayHeight.redacted
                } else {
                    state.birthdayHeightValue = nil
                }
                return .none
                
            case .binding:
                return .none
                
            case .dismissAlert:
                state.alert = nil
                return .none
                
            case .restoreWallet:
                do {
                    // validate the seed
                    try mnemonic.isValid(state.importedSeedPhrase.data)
                    
                    // store it to the keychain
                    let birthday = state.birthdayHeightValue ?? zcashSDKEnvironment.defaultBirthday.redacted
                    try walletStorage.importWallet(state.importedSeedPhrase.data, birthday.data, .english, false)
                    
                    // update the backup phrase validation flag
                    try walletStorage.markUserPassedPhraseBackupTest()
                    
                    // notify user
                    // TODO: [#221] Proper Error/Success handling (https://github.com/zcash/secant-ios-wallet/issues/221)
                    state.alert = AlertState(
                        title: TextState("Success"),
                        message: TextState("The wallet has been successfully recovered."),
                        dismissButton: .default(
                            TextState("Ok"),
                            action: .send(.successfullyRecovered)
                        )
                    )
                    
                    return EffectTask(value: .initializeSDK)
                } catch {
                    // TODO: [#221] Proper Error/Success handling (https://github.com/zcash/secant-ios-wallet/issues/221)
                    state.alert = AlertState(
                        title: TextState("Wrong Seed Phrase"),
                        message: TextState("The seed phrase must be 24 words separated by space."),
                        dismissButton: .default(
                            TextState("Ok"),
                            action: .send(.dismissAlert)
                        )
                    )
                }
                
                return .none
                
            case .importPrivateOrViewingKey:
                return .none
                
            case .successfullyRecovered:
                return EffectTask(value: .dismissAlert)
                
            case .initializeSDK:
                return .none
            }
        }
    }
}

// MARK: - ViewStore

extension ImportWalletViewStore {
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
}

// MARK: - Placeholders

extension ImportWalletReducer.State {
    static let placeholder = ImportWalletReducer.State()

    static let live = ImportWalletReducer.State()
}

extension ImportWalletStore {
    static let demo = Store(
        initialState: .placeholder,
        reducer: ImportWalletReducer()
    )
}
