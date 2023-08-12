//
//  NotificationsStore.swift
//  secant
//
//  Created by Matthew Watt on 5/14/23.
//

import ComposableArchitecture

public struct NotificationsReducer: ReducerProtocol {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {}
    
    public var body: some ReducerProtocol<NotificationsReducer.State, NotificationsReducer.Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension NotificationsReducer.State {
    public static let placeholder = Self()
}
