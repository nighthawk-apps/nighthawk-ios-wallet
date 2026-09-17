//
//  AudioServicesInterface.swift
//  stealth
//

import ComposableArchitecture
import AVFoundation

extension DependencyValues {
    public var audioServices: AudioServicesClient {
        get { self[AudioServicesClient.self] }
        set { self[AudioServicesClient.self] = newValue }
    }
}

public struct AudioServicesClient {
    public let systemSoundVibrate: () -> Void

    public init(systemSoundVibrate: @escaping () -> Void) {
        self.systemSoundVibrate = systemSoundVibrate
    }
}
