//
//  ProcessInfoClient.swift
//
//
//  Created by Matthew Watt on 10/4/23.
//

import ComposableArchitecture
import Foundation

public struct ProcessInfoClient {
    public var isiOSAppOnMac: () -> Bool
}

extension ProcessInfoClient: DependencyKey {
    public static let liveValue = Self(
        isiOSAppOnMac: {
            ProcessInfo.processInfo.isiOSAppOnMac
        }
    )
}

extension DependencyValues {
    public var processInfo: ProcessInfoClient {
        get { self[ProcessInfoClient.self] }
        set { self[ProcessInfoClient.self] = newValue }
    }
}

