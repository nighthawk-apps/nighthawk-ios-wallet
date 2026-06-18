//
//  ExportSeed.swift
//  
//
//  Created by Matthew Watt on 9/8/23.
//

import ComposableArchitecture
import MnemonicClient
import Models
import SwiftUI
import Utils
import WalletStorage

@Reducer
public struct ExportSeed {
    @ObservableState
    public struct State: Equatable {
        public var password = ""
        public var isPasswordVisible = false
        public var phrase: RecoveryPhrase = .empty
        public var birthday: BlockHeight = .zero
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case cancelTapped
        case onAppear
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.walletStorage) var walletStorage
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .cancelTapped:
                return .run { _ in await self.dismiss() }
            case .onAppear:
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    let phraseWords = mnemonic.asWords(storedWallet.seedPhrase.value())
                    state.phrase = RecoveryPhrase(words: phraseWords.map { $0.redacted })
                    // DarkFi: no checkpoint concept
                    state.birthday = storedWallet.birthday?.value() ?? 0
                    return .none
                } catch {
                    return .none
                }
            }
        }
    }
    
    public init() {}
}
