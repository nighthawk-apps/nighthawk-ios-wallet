//
//  Sending.swift
//  
//
//  Created by Matthew Watt on 8/1/23.
//

import ComposableArchitecture

public struct Sending: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    public var body: some ReducerProtocolOf<Self> {
        Reduce { _, _ in .none }
    }
}
