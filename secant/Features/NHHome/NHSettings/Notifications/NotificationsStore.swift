//
//  NotificationsStore.swift
//  secant
//
//  Created by Matthew Watt on 5/14/23.
//

import ComposableArchitecture

struct NotificationsReducer: ReducerProtocol {
    struct State: Equatable {}
    enum Action: Equatable {}
    
    var body: some ReducerProtocol<NotificationsReducer.State, NotificationsReducer.Action> {
        Reduce { _, _ in .none }
    }
}

// MARK: - Placeholder
extension NotificationsReducer.State {
    static let placeholder = Self()
}
