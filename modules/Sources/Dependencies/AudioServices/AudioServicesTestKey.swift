//
//  AudioServicesTestKey.swift
//  stealth
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension AudioServicesClient: TestDependencyKey {
    public static let testValue = Self(
        systemSoundVibrate: unimplemented("\(Self.self).systemSoundVibrate")
    )
}
