//
//  ApplicationClient.swift
//
//
//  Created by Matthew Watt on 10/27/23.
//

import ComposableArchitecture
import Foundation
import UIKit

public struct ApplicationClient {
    public var canOpenURL: (URL) -> Bool
    public var open: (URL, [UIApplication.OpenExternalURLOptionsKey : Any]) async -> Void
    public var supportsAlternateIcons: () -> Bool
    public var setAlternateIconName: (String?) async throws -> Void
    public var isIdleTimerDisabled: () -> Bool
    public var setIsIdleTimerDisabled: (Bool) -> Void
}

extension ApplicationClient: DependencyKey {
    public static let liveValue = Self(
        canOpenURL: { UIApplication.shared.canOpenURL($0) },
        open: { url, options in
            await UIApplication.shared.open(url, options: options)
        },
        supportsAlternateIcons: { UIApplication.shared.supportsAlternateIcons },
        setAlternateIconName: { iconName in
            return try await UIApplication.shared.setAlternateIconName(iconName)
        },
        isIdleTimerDisabled: { UIApplication.shared.isIdleTimerDisabled },
        setIsIdleTimerDisabled: { UIApplication.shared.isIdleTimerDisabled = $0 }
    )
}

extension DependencyValues {
    public var application: ApplicationClient {
        get { self[ApplicationClient.self] }
        set { self[ApplicationClient.self] = newValue }
    }
}

