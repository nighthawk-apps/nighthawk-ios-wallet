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

public struct AddMemo: Reducer {
    public struct State: Equatable {
        public var internalMemo = "".redacted
        public var memoCharLimit = 0
        public var unifiedAddress: UnifiedAddress?
        
        public var hasEnteredMemo: Bool { !internalMemo.data.isEmpty }
        public var memo: RedactableString {
            if isIncludeReplyToChecked, !internalMemo.data.isEmpty, let sapling = (try? unifiedAddress?.saplingReceiver().stringEncoded) {
                "\(internalMemo.data)\nReply-To: \(sapling)".redacted
            } else {
                internalMemo
            }
        }
        @BindingState public var isIncludeReplyToChecked = false
        
        public init(unifiedAddress: UnifiedAddress?) {
            self.unifiedAddress = unifiedAddress
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case backButtonTapped
        case binding(BindingAction<State>)
        case continueOrSkipTapped
        case delegate(Delegate)
        case memoInputChanged(RedactableString)
        
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
            case .binding:
                return .none
            case .continueOrSkipTapped:
                return .send(.delegate(.nextScreen))
            case .delegate:
                return .none
            case .memoInputChanged(let redactedmemo):
                guard redactedmemo.data.count <= state.memoCharLimit else { return .none }
                state.internalMemo = redactedmemo
                return .none
            }
        }
    }
    
    public init() {}
}

// MARK: - ViewStore
extension ViewStoreOf<AddMemo> {
    func bindingForRedactableMemo(_ memo: RedactableString) -> Binding<String> {
        self.binding(
            get: { _ in memo.data },
            send: { .memoInputChanged($0.redacted) }
        )
    }
}
