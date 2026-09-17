//
//  AppVersionLiveKey.swift
//  stealth
//

import Foundation
import ComposableArchitecture

extension AppVersionClient: DependencyKey {
    public static let liveValue = Self(
        appVersion: { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" },
        appBuild: { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "" }
    )
}
