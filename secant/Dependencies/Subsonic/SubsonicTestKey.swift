//
//  SubsonicTextKey.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

extension SubsonicClient: TestDependencyKey {
    static let testValue = Self(
        play: XCTUnimplemented("\(Self.self).play")
    )
}
