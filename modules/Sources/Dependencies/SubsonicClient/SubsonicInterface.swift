//
//  SubsonicInterface.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

public extension DependencyValues {
    var subsonic: SubsonicClient {
        get { self[SubsonicClient.self] }
        set { self[SubsonicClient.self] = newValue }
    }
}

public struct SubsonicClient {
    public let play: (String) -> Void
}
