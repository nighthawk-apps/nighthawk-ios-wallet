//
//  About.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ApplicationClient
import ComposableArchitecture
import UIKit
import Utils

public struct About: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case delegate(Delegate)
        case nighthawkFriendsTapped
        case viewLicensesTapped
        case viewSourceTapped
        case termsAndConditionsTapped
        
        public enum Delegate: Equatable {
            case showLicensesList
        }
    }
    
    @Dependency(\.application) var application
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case .nighthawkFriendsTapped:
                return .run { _ in await application.open(.friends, [:]) }
            case .viewLicensesTapped:
                return .send(.delegate(.showLicensesList))
            case .viewSourceTapped:
                return .run { _ in await application.open(.source, [:]) }
            case .termsAndConditionsTapped:
                return .run { _ in await application.open(.terms, [:]) }
            }
        }
    }
    
    public init() {}
}
