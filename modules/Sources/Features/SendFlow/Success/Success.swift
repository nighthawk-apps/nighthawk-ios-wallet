//
//  Success.swift
//  
//
//  Created by Matthew Watt on 8/2/23.
//

import ComposableArchitecture

public struct Success: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case doneTapped
        case moreDetailsTapped
    }
    
    public init() {}
    
    public var body: some ReducerProtocolOf<Self> {
        Reduce { _, _ in .none }
    }
}
