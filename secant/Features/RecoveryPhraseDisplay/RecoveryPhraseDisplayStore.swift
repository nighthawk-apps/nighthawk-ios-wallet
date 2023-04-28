//
//  RecoveryPhraseDisplayStore.swift
//  secant-testnet
//
//  Created by Francisco Gindre on 10/26/21.
//

import Foundation
import ComposableArchitecture
import ZcashLightClientKit

typealias RecoveryPhraseDisplayStore = Store<RecoveryPhraseDisplayReducer.State, RecoveryPhraseDisplayReducer.Action>

struct RecoveryPhraseDisplayReducer: ReducerProtocol {
    struct State: Equatable {
        enum RecoveryPhraseDisplayFlow {
            case onboarding
            case settings
        }
        
        var flow: RecoveryPhraseDisplayFlow
        var phrase: RecoveryPhrase?
        var birthday: BlockHeight?
        var showCopyToBufferAlert = false
        @BindingState var isConfirmSeedPhraseWrittenChecked = false
    }
    
    enum Action: BindableAction, Equatable {
        case onAppear
        case copyToBufferPressed
        case finishedPressed
        case phraseResponse(RecoveryPhrase)
        case binding(BindingAction<State>)
    }
    
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.walletStorage) var walletStorage
    
    var body: some ReducerProtocol<State, Action> {
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
    static let demo = AnyReducer<RecoveryPhraseDisplayReducer.State, RecoveryPhraseDisplayReducer.Action, Void> { _ in
        RecoveryPhraseDisplayReducer()
    }
}
