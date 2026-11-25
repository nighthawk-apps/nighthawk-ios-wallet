//
//  About.swift
//  stealth
//
//  Created by Matthew Watt on 5/22/23.
//

import AppVersion
import ComposableArchitecture
import UIKit
import Utils

@Reducer
public struct About {
    @ObservableState
    public struct State: Equatable {
        public var appVersion: String = ""
        public var appBuild: String = ""

        public var versionDisplay: String {
            if !appVersion.isEmpty && !appBuild.isEmpty {
                return "Version \(appVersion) (\(appBuild))"
            }
            if !appVersion.isEmpty {
                return "Version \(appVersion)"
            }
            return ""
        }

        public init() {}
    }

    public enum Action: Equatable {
        case delegate(Delegate)
        case onAppear
        case viewLicensesTapped
        case viewSourceTapped

        public enum Delegate: Equatable {
            case showLicensesList
        }
    }

    @Dependency(\.appVersion) var appVersion

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .onAppear:
                state.appVersion = appVersion.appVersion()
                state.appBuild = appVersion.appBuild()
                return .none
            case .viewLicensesTapped:
                return .send(.delegate(.showLicensesList))
            case .viewSourceTapped:
                UIApplication.shared.open(.source, options: [:], completionHandler: nil)
                return .none
            }
        }
    }

    public init() {}
}
