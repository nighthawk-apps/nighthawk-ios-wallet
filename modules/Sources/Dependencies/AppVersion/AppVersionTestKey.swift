//
//  AppVersionTestKey.swift
//  stealth
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension AppVersionClient: TestDependencyKey {
    public static let testValue = Self(
        appVersion: unimplemented("\(Self.self).appVersion", placeholder: ""),
        appBuild: unimplemented("\(Self.self).appBuild", placeholder: "")
    )
}
