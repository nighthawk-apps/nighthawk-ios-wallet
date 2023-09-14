//
//  AddMemo.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import SwiftUI
import Utils

public struct AddMemo: ReducerProtocol {
    public struct State: Equatable {
        public var memo = "".redacted
        public var memoCharLimit = 0
        public var hasEnteredMemo: Bool { !memo.data.isEmpty }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case continueOrSkipTapped
        case memoInputChanged(RedactableString)
    }
    
    public init() {}
    
    @Dependency(\.dismiss) var dismiss
    
    public var body: some ReducerProtocolOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in await self.dismiss() }
            case .memoInputChanged(let redactedmemo):
                guard redactedmemo.data.count <= state.memoCharLimit else { return .none }
                state.memo = redactedmemo
                return .none
            case .continueOrSkipTapped:
                return .none
            }
        }
    }
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
