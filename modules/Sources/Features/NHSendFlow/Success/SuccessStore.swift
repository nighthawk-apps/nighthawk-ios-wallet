//
//  SuccessStore.swift
//  
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture

public typealias SuccessStore = Store<SuccessReducer.State, SuccessReducer.Action>
public typealias SuccessViewStore = Store<SuccessReducer.State, SuccessReducer.Action>

public struct SuccessReducer: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case doneTapped
        case moreDetailsTapped
    }
    
    public init() {}
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in .none }
    }
}
