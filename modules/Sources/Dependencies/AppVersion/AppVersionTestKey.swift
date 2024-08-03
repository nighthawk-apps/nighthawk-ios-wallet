//
//  AppVersionTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension AppVersionClient: TestDependencyKey {
    public static let testValue = Self(
        appVersion: unimplemented("\(Self.self).appVersion", placeholder: ""),
        appBuild: unimplemented("\(Self.self).appBuild", placeholder: "")
    )
}
