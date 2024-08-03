//
//  ExternalServices.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import UserPreferencesStorage

@Reducer
public struct ExternalServices {
    public struct State: Equatable {
        @BindingState public var isUnstoppableDomainsEnabled = false
        
        public init() {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            isUnstoppableDomainsEnabled = userStoredPreferences.isUnstoppableDomainsEnabled()
        }
    }
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }
    
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding(\.$isUnstoppableDomainsEnabled):
                userStoredPreferences.setIsUnstoppableDomainsEnabled(state.isUnstoppableDomainsEnabled)
                return .none
            case .binding:
                return .none
            }
        }
    }
    
    public init() {}
}
