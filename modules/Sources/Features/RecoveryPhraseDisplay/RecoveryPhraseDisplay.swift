//
//  RecoveryPhraseDisplay.swift
//  secant-testnet
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import ExportSeed
import Foundation
import MnemonicClient
import Models
import Pasteboard
import WalletStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct RecoveryPhraseDisplay {
    let zcashNetwork: ZcashNetwork
    
    public struct State: Equatable {
        public enum RecoveryPhraseDisplayFlow {
            case onboarding
            case settings
        }
        
        @PresentationState public var destination: Destination.State?
        public var flow: RecoveryPhraseDisplayFlow
        public var phrase: RecoveryPhrase = .empty
        public var birthday: BlockHeight = .zero
        @BindingState public var isConfirmSeedPhraseWrittenChecked = false
        
        public init(flow: RecoveryPhraseDisplayFlow) {
            self.flow = flow
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case continuePressed
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case exportAsPdfPressed
        case onAppear
        
        public enum Delegate: Equatable {
            case initializeSDKAndLaunchWallet
        }
    }
    
    public struct Destination: Reducer {
        let zcashNetwork: ZcashNetwork
        
        public enum State: Equatable {
            case exportSeedAlert(ExportSeed.State)
        }
        
        public enum Action: Equatable {
            case exportSeedAlert(ExportSeed.Action)
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.exportSeedAlert, action: /Action.exportSeedAlert) {
                ExportSeed(zcashNetwork: zcashNetwork)
            }
        }
        
        public init(zcashNetwork: ZcashNetwork) {
            self.zcashNetwork = zcashNetwork
        }
    }
    
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
        
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .continuePressed:
                return .send(.delegate(.initializeSDKAndLaunchWallet))
            case .delegate:
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
                    state.phrase = RecoveryPhrase(words: phraseWords.map { $0.redacted })
                    state.birthday = storedWallet.birthday?.value() ?? zcashSDKEnvironment.latestCheckpoint(zcashNetwork)
                    return .none
                } catch {
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination(zcashNetwork: zcashNetwork)
        }
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }
}
