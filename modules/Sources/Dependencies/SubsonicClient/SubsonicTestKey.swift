//
//  SubsonicTextKey.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

extension SubsonicClient: TestDependencyKey {
    public static let testValue = Self(
        play: unimplemented("\(Self.self).play")
    )
}
