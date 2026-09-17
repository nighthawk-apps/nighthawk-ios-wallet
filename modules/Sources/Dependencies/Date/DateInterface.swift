//
//  DateClient.swift
//  stealth
//

import Foundation
import ComposableArchitecture

extension DependencyValues {
    public var dateClient: DateClient {
        get { self[DateClient.self] }
        set { self[DateClient.self] = newValue }
    }
}

public struct DateClient {
    public let now: () -> Date

    public init(now: @escaping () -> Date) {
        self.now = now
    }
}
