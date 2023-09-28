//
//  About.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import UIKit
import Utils

public struct About: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case delegate(Delegate)
        case viewLicensesTapped
        case viewSourceTapped
        case termsAndConditionsTapped
        
        public enum Delegate: Equatable {
            case showLicensesList
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .delegate:
                return .none
            case .viewLicensesTapped:
                return .send(.delegate(.showLicensesList))
            case .viewSourceTapped:
                UIApplication.shared.open(.source, options: [:], completionHandler: nil)
                return .none
            case .termsAndConditionsTapped:
                UIApplication.shared.open(.terms, options: [:], completionHandler: nil)
                return .none
            }
        }
    }
    
    public init() {}
}
