//
//  RecoveryPhraseDisplayStore.swift
//  secant-testnet
//
//  Created by Francisco Gindre on 10/26/21.
//

import ComposableArchitecture
import ExportSeed
import Foundation
import MnemonicClient
import Models
import Pasteboard
import WalletStorage
import ZcashLightClientKit

public typealias RecoveryPhraseDisplayStore = Store<RecoveryPhraseDisplayReducer.State, RecoveryPhraseDisplayReducer.Action>

public struct RecoveryPhraseDisplayReducer: ReducerProtocol {
    public struct State: Equatable {
        public enum RecoveryPhraseDisplayFlow {
            case onboarding
            case settings
        }
        
        @PresentationState public var destination: Destination.State?
        public var flow: RecoveryPhraseDisplayFlow
        public var phrase: RecoveryPhrase?
        public var birthday: BlockHeight?
        @BindingState public var isConfirmSeedPhraseWrittenChecked = false
        
        public init(flow: RecoveryPhraseDisplayFlow) {
            self.flow = flow
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case continuePressed
        case destination(PresentationAction<Destination.Action>)
        case exportAsPdfPressed
        case onAppear
    }
    
    public struct Destination: ReducerProtocol {
        public enum State: Equatable {
            case exportSeedAlert(ExportSeed.State)
        }
        
        public enum Action: Equatable {
            case exportSeedAlert(ExportSeed.Action)
        }
        
        public var body: some ReducerProtocolOf<Self> {
            Reduce { _, _ in .none }
        }
        
        public init() {}
    }
    
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.walletStorage) var walletStorage
    
    public init() {}
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .continuePressed:
                return .none
            case .destination(.dismiss):
                return .none
            case .destination:
                return .none
            case .exportAsPdfPressed:
                state.destination = .exportSeedAlert(.init())
                return .none
                
            case .onAppear:
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    let phraseWords = mnemonic.asWords(storedWallet.seedPhrase.value())
                    let recoveryPhrase = RecoveryPhrase(words: phraseWords.map { $0.redacted })
                    state.phrase = recoveryPhrase
                    state.birthday = storedWallet.birthday?.value()
                } catch {
                    return .none
                }
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}
