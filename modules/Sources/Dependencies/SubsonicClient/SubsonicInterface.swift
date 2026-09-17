//
//  SubsonicInterface.swift
//  stealth
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
