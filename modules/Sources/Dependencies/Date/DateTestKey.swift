//
//  DateTestKey.swift
//  stealth
//
//  Created by Lukáš Korba on 15.11.2022.
//

import Foundation
import ComposableArchitecture
import IssueReporting

extension DateClient: TestDependencyKey {
    public static let testValue = Self(
        now: unimplemented("\(Self.self).now", placeholder: Date.now)
    )
}
