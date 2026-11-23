//
//  DerivationToolTestKey.swift
//  stealth
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture
import IssueReporting
import Utils

extension DerivationToolClient: TestDependencyKey {
    public static let testValue = Self(
        isDarkFiAddress: unimplemented("\(Self.self).isDarkFiAddress", placeholder: false)
    )
}

extension DerivationToolClient {
    public static let noOp = Self(
        isDarkFiAddress: { _, _ in return false }
    )
}
