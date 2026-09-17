//
//  DateLiveKey.swift
//  stealth
//

import Foundation
import ComposableArchitecture

extension DateClient: DependencyKey {
    public static let liveValue = Self(
        now: { Date.now }
    )
}
