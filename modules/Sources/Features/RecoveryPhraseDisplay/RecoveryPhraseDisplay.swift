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

public struct RecoveryPhraseDisplay: ReducerProtocol {
    public struct State: Equatable {
        public enum RecoveryPhraseDisplayFlow {
            case onboarding
            case settings
        }
        
        @PresentationState public var destination: Destination.State?
        public var flow: RecoveryPhraseDisplayFlow
        public var phrase: RecoveryPhrase
        public var birthday: BlockHeight
        @BindingState public var isConfirmSeedPhraseWrittenChecked = false
        
        public init(
            flow: RecoveryPhraseDisplayFlow,
            phrase: RecoveryPhrase,
            birthday: BlockHeight
        ) {
            self.flow = flow
            self.phrase = phrase
            self.birthday = birthday
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case continuePressed
        case destination(PresentationAction<Destination.Action>)
        case exportAsPdfPressed
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
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}
