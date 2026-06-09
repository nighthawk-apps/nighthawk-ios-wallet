//
//  ImportWallet.swift
//  stealth
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

@Reducer
public struct ImportWallet {
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var importedSeedPhrase = ""
        public var birthdayHeight = ""
        public var maxWordsCount = DarkfiSeedPhrase.wordCount
        public var birthdayHeightValue: RedactableBlockHeight? { BlockHeight(birthdayHeight)?.redacted }
        public var formattedPhrase: String {
            let trimmedPhraseWords = importedSeedPhrase.split(separator: " ")
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .whitespaces) }
            return trimmedPhraseWords.joined(separator: " ")
        }
        public var isValidMnemonic: Bool {
            @Dependency(\.mnemonic) var mnemonic
            return mnemonic.isValid(formattedPhrase)
        }
        
        public var isValidBirthday: Bool {
            if let birthdayHeightValue {
                return birthdayHeightValue.data >= 0
            }
            return true
        }
        
        public var isValidForm: Bool { isValidBirthday && isValidMnemonic }
                
        public init() {}
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
    
    public var body: some ReducerOf<ImportWallet> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .binding:
                return .none
            case .continueTapped:
                guard state.isValidForm else { return .none }
                do {
                    // if the user did not input a height,
                    // fall back to 0 (DarkFi: no checkpoint concept)
                    let birthday = state.birthdayHeightValue ?? BlockHeight(0).redacted
                    try walletStorage.importWallet(state.formattedPhrase, birthday.data, .english)
                    return .send(.delegate(.showImportSuccess))
                } catch {
                    state.alert = AlertState.importWalletFailed(error.toDarkFiError())
                    return .none
                }
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    public init() {}
}

extension AlertState where Action == ImportWallet.Action.Alert {
    static func importWalletFailed(_ error: DarkfiError) -> Self {
        AlertState {
            TextState(L10n.Nighthawk.ImportWallet.Alert.Failed.title)
        } message: {
            TextState(L10n.Nighthawk.ImportWallet.Alert.Failed.message(error.message, 0))
        }
    }
}
