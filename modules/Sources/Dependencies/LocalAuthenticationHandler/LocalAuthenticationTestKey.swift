//
//  LocalAuthenticationTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension LocalAuthenticationClient: TestDependencyKey {
    public static let testValue = Self(
        authenticate: XCTUnimplemented("\(Self.self).authenticate", placeholder: false),
        biometryType: XCTUnimplemented("\(Self.self).biometryType", placeholder: .none),
        context: XCTUnimplemented("\(Self.self).context")
    )
}
