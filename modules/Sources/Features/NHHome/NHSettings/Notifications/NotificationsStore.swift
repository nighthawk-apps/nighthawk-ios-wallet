//
//  NotificationsStore.swift
//  secant
//
//  Created by Matthew Watt on 5/14/23.
//

import ComposableArchitecture
import Models
import NHUserPreferencesStorage

public struct NotificationsReducer: ReducerProtocol {
    public struct State: Equatable {
        @BindingState public var selectedSyncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency = .off
        
        public init() {}
    }
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
    }
    
    @Dependency(\.nhUserStoredPreferences) var nhUserStoredPreferences
    
    public var body: some ReducerProtocol<NotificationsReducer.State, NotificationsReducer.Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.selectedSyncNotificationFrequency = nhUserStoredPreferences.syncNotificationFrequency()
                return .none
            case .binding(\.$selectedSyncNotificationFrequency):
                nhUserStoredPreferences.setSyncNotificationFrequency(state.selectedSyncNotificationFrequency)
                return .none
            case .binding:
                return .none
            }
        }
    }
}

// MARK: - Placeholder
extension NotificationsReducer.State {
    public static let placeholder = Self()
}
