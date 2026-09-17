//
//  DateTestKey.swift
//  stealth
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay

extension DateClient: TestDependencyKey {
    public static let testValue = Self(
        now: unimplemented("\(Self.self).now", placeholder: Date.now)
    )
}
