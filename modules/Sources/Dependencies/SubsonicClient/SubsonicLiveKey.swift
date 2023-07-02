//
//  SubsonicLiveKey.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import Subsonic

extension SubsonicClient: DependencyKey {
    public static let liveValue = Self(
        play: { filename in SubsonicController.shared.play(sound: filename) }
    )
}
