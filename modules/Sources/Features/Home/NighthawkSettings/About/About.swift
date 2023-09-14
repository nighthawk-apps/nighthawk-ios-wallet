//
//  About.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

public struct About: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    
    public var body: some ReducerProtocolOf<Self> {
        Reduce { _, _ in .none }
    }
    
    public init() {}
}

// MARK: - Placeholder
extension About.State {
    public static let placeholder = Self()
}
