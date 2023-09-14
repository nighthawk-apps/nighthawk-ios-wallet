//
//  Fiat.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture

public struct Fiat: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    
    public var body: some ReducerProtocolOf<Self> {
        Reduce { _, _ in
            return .none
        }
    }
    
    public init() {}
}

// MARK: - Placeholder
extension Fiat.State {
    public static var placeholder = Self()
}
