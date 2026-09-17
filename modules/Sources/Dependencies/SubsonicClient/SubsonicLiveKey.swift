//
//  SubsonicLiveKey.swift
//  stealth
//

import ComposableArchitecture
import Subsonic

extension SubsonicClient: DependencyKey {
    public static let liveValue = Self(
        play: { filename in SubsonicController.shared.play(sound: filename) }
    )
}
