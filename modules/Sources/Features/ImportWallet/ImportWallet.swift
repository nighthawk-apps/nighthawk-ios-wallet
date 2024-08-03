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

@Reducer
public struct ImportWallet {
    let saplingActivationHeight: BlockHeight
    
    public struct State: Equatable {
        let saplingActivationHeight: BlockHeight
        @PresentationState public var alert: AlertState<Action.Alert>?
        @BindingState public var importedSeedPhrase = ""
        @BindingState public var birthdayHeight = ""
        public var maxWordsCount = 0
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
                return birthdayHeightValue.data >= saplingActivationHeight
            }
                        
            return true
        }
        
        public var isValidForm: Bool { isValidBirthday && isValidMnemonic }
                
        public init(saplingActivationHeight: BlockHeight) {
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            maxWordsCount = zcashSDKEnvironment.mnemonicWordsMaxCount
            self.saplingActivationHeight = saplingActivationHeight
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
            case .binding:
                return .none
            case .continueTapped:
                guard state.isValidForm else { return .none }
                do {
                    // if the user did not input a height,
                    // fall back to sapling activation
                    let birthday = state.birthdayHeightValue ?? saplingActivationHeight.redacted
                    try walletStorage.importWallet(state.formattedPhrase, birthday.data, .english)
                    return .send(.delegate(.showImportSuccess))
                } catch {
                    state.alert = AlertState.importWalletFailed(error.toZcashError())
                    return .none
                }
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
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
