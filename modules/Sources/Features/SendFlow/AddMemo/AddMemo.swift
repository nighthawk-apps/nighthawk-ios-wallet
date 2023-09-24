//
//  AddMemo.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import SwiftUI
import Utils

public struct AddMemo: Reducer {
    public struct State: Equatable {
        public var memo = "".redacted
        public var memoCharLimit = 0
        public var hasEnteredMemo: Bool { !memo.data.isEmpty }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case continueOrSkipTapped
        case delegate(Delegate)
        case memoInputChanged(RedactableString)
        
        public enum Delegate: Equatable {
            case goBack
            case nextScreen
        }
    }
        
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .send(.delegate(.goBack))
            case .continueOrSkipTapped:
                return .send(.delegate(.nextScreen))
            case .delegate:
                return .none
            case .memoInputChanged(let redactedmemo):
                guard redactedmemo.data.count <= state.memoCharLimit else { return .none }
                state.memo = redactedmemo
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
