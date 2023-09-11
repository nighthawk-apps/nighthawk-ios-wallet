//
//  ExportSeed.swift
//  
//
//  Created by Matthew Watt on 9/8/23.
//

import ComposableArchitecture

public struct ExportSeed: ReducerProtocol {
    public struct State: Equatable {
        @BindingState public var password = ""
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }
    
    public var body: some ReducerProtocolOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            }
        }
    }
    
    public init() {}
}
