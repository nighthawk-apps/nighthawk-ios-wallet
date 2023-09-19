//
//  Sending.swift
//  
//
//  Created by Matthew Watt on 8/1/23.
//

import ComposableArchitecture

public struct Sending: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
