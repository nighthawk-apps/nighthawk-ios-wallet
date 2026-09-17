//
//  AudioServicesLiveKey.swift
//  stealth
//

import AVFoundation
import ComposableArchitecture

extension AudioServicesClient: DependencyKey {
    public static let liveValue = Self(
        systemSoundVibrate: { AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate)) }
    )
}
