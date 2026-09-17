//
//  AppVersionInterface.swift
//  stealth
//

import ComposableArchitecture

extension DependencyValues {
    public var appVersion: AppVersionClient {
        get { self[AppVersionClient.self] }
        set { self[AppVersionClient.self] = newValue }
    }
}

public struct AppVersionClient {
    public let appVersion: () -> String
    public let appBuild: () -> String

    public init(appVersion: @escaping () -> String, appBuild: @escaping () -> String) {
        self.appVersion = appVersion
        self.appBuild = appBuild
    }
}
