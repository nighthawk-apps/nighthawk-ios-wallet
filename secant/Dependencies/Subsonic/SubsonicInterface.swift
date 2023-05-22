//
//  SubsonicInterface.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture

extension DependencyValues {
    var subsonic: SubsonicClient {
        get { self[SubsonicClient.self] }
        set { self[SubsonicClient.self] = newValue }
    }
}

struct SubsonicClient {
    let play: (String) -> Void
}
