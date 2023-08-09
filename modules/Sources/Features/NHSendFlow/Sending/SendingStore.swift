//
//  SendingStore.swift
//  
//
//  Created by Matthew Watt on 8/1/23.
//

import ComposableArchitecture

public typealias SendingStore = Store<SendingReducer.State, SendingReducer.Action>
public typealias SendingViewStore = ViewStore<SendingReducer.State, SendingReducer.Action>

public struct SendingReducer: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}
