//
//  AddMemo.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import SDKSynchronizer
import SwiftUI
import Utils
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct AddMemo: Reducer {
    public struct State: Equatable {
        @BindingState public var memo = ""
        @BindingState public var isIncludeReplyToChecked = false
        public var memoCharLimit = 0
        public var unifiedAddress: UnifiedAddress?
        public var hasEnteredMemo: Bool { !memo.isEmpty }
        public var canIncludeReplyTo: Bool {
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            guard let ua = unifiedAddress?.stringEncoded else { return false }
            let prefix = zcashSDKEnvironment.replyToPrefix
            return hasEnteredMemo && "\(memo)\n\(prefix)\(ua)".count <= memoCharLimit
        }
        
        public init(unifiedAddress: UnifiedAddress?) {
            self.unifiedAddress = unifiedAddress
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case backButtonTapped
        case binding(BindingAction<State>)
        case continueOrSkipTapped
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case goBack
            case nextScreen
        }
    }
    
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
        
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .send(.delegate(.goBack))
            case .binding(\.$memo):
                if state.memo.count >= state.memoCharLimit {
                    state.memo = String(state.memo.prefix(state.memoCharLimit))
                }
                return .none
            case .binding:
                return .none
            case .continueOrSkipTapped:
                return .send(.delegate(.nextScreen))
            case .delegate:
                return .none
            }
        }
    }
    
    public init() {}
}
