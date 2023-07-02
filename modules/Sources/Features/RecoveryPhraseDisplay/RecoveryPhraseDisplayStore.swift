//
//  RecoveryPhraseDisplayStore.swift
//  secant-testnet
//
//  Created by Francisco Gindre on 10/26/21.
//

import Foundation
import ComposableArchitecture
import ZcashLightClientKit
import Models
import Pasteboard
import WalletStorage

public typealias RecoveryPhraseDisplayStore = Store<RecoveryPhraseDisplayReducer.State, RecoveryPhraseDisplayReducer.Action>

public struct RecoveryPhraseDisplayReducer: ReducerProtocol {
    public struct State: Equatable {
        public enum RecoveryPhraseDisplayFlow {
            case onboarding
            case settings
        }
        
        public var flow: RecoveryPhraseDisplayFlow
        public var phrase: RecoveryPhrase?
        public var birthday: BlockHeight?
        public var showCopyToBufferAlert = false
        @BindingState public var isConfirmSeedPhraseWrittenChecked = false
        
        public init(
            flow: RecoveryPhraseDisplayFlow,
            phrase: RecoveryPhrase? = nil,
            birthday: BlockHeight? = nil,
            showCopyToBufferAlert: Bool = false,
            isConfirmSeedPhraseWrittenChecked: Bool = false
        ) {
            self.flow = flow
            self.phrase = phrase
            self.birthday = birthday
            self.showCopyToBufferAlert = showCopyToBufferAlert
            self.isConfirmSeedPhraseWrittenChecked = isConfirmSeedPhraseWrittenChecked
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case onAppear
        case copyToBufferPressed
        case finishedPressed
        case phraseResponse(RecoveryPhrase)
        case binding(BindingAction<State>)
    }
    
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.walletStorage) var walletStorage
    
    public init() {}
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .copyToBufferPressed:
                guard let phrase = state.phrase?.toString() else { return .none }
                pasteboard.setString(phrase)
                state.showCopyToBufferAlert = true
                return .none
                
            case .finishedPressed:
                return .none
                
            case let .phraseResponse(phrase):
                state.phrase = phrase
                return .none
                
            case .onAppear:
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    state.birthday = storedWallet.birthday?.value()
                } catch {
                    return .none
                }
                return .none
            case .binding:
                return .none
            }
        }
    }
}

extension RecoveryPhraseDisplayReducer {
    public static let demo = AnyReducer<RecoveryPhraseDisplayReducer.State, RecoveryPhraseDisplayReducer.Action, Void> { _ in
        RecoveryPhraseDisplayReducer()
    }
}
