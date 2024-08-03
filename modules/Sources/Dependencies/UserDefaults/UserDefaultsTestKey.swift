//
//  UserDefaultsTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension UserDefaultsClient: TestDependencyKey {
    public static let testValue = Self(
        objectForKey: unimplemented("\(Self.self).objectForKey", placeholder: nil),
        remove: unimplemented("\(Self.self).remove"),
        setValue: unimplemented("\(Self.self).setValue")
    )
}

extension UserDefaultsClient {
    public static let noOp = Self(
        objectForKey: { _ in nil },
        remove: { _ in },
        setValue: { _, _ in }
    )
}
