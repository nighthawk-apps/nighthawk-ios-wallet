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
import WalletStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct ExportSeed {
    let zcashNetwork: ZcashNetwork
    
    public struct State: Equatable {
        @BindingState public var password = ""
        @BindingState public var isPasswordVisible = false
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
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
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
                    state.birthday = storedWallet.birthday?.value() ?? zcashSDKEnvironment.latestCheckpoint(zcashNetwork)
                    return .none
                } catch {
                    return .none
                }
            }
        }
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }
}
