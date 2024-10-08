//
//  Fiat.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import Models
import UserPreferencesStorage
import ZcashSDKEnvironment

@Reducer
public struct Fiat {
    
    @ObservableState
    public struct State: Equatable {
        public var selectedFiatCurrency: NighthawkSetting.FiatCurrency
        public var tokenName: String {
            @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
            return zcashSDKEnvironment.tokenName
        }
        
        public init() {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            self.selectedFiatCurrency = userStoredPreferences.fiatCurrency()
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case fetchLatestFiatCurrency
        }
    }
    
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding(\.selectedFiatCurrency):
                userStoredPreferences.setFiatCurrency(state.selectedFiatCurrency)
                return .send(.delegate(.fetchLatestFiatCurrency))
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
    }
    
    public init() {}
}
