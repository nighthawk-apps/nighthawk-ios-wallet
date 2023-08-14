//
//  MigrateStore.swift
//  
//
//  Created by Matthew Watt on 8/12/23.
//

import ComposableArchitecture

public typealias MigrateStore = Store<MigrateReducer.State, MigrateReducer.Action>
public typealias MigrateViewStore = ViewStore<MigrateReducer.State, MigrateReducer.Action>

public struct MigrateReducer: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case continueTapped
        case restoreManuallyTapped
    }
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            return .none
        }
    }
    
    public init() {}
}

// MARK: - Placeholder
extension MigrateReducer.State {
    public static var placeholder: Self {
        .init()
    }
}
