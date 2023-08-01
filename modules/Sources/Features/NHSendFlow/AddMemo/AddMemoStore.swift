//
//  AddMemoStore.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import SwiftUI
import Utils

public typealias AddMemoStore = Store<AddMemoReducer.State, AddMemoReducer.Action>
public typealias AddMemoViewStore = ViewStore<AddMemoReducer.State, AddMemoReducer.Action>

public struct AddMemoReducer: ReducerProtocol {
    public struct State: Equatable {
        public var memo = "".redacted
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
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in await self.dismiss() }
            case .memoInputChanged(let redactedmemo):
                state.memo = redactedmemo
                return .none
            case .continueOrSkipTapped:
                return .none
            }
        }
    }
}

// MARK: - ViewStore
extension AddMemoViewStore {
    func bindingForRedactableMemo(_ memo: RedactableString) -> Binding<String> {
        self.binding(
            get: { _ in memo.data },
            send: { .memoInputChanged($0.redacted) }
        )
    }
}
