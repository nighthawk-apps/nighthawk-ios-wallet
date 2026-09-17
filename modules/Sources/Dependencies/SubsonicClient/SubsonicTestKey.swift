//
//  SubsonicTextKey.swift
//  stealth
//

import ComposableArchitecture

extension SubsonicClient: TestDependencyKey {
    public static let testValue = Self(
        play: unimplemented("\(Self.self).play")
    )
}
