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
        deriveSpendingKey: unimplemented("\(Self.self).deriveSpendingKey"),
        deriveFullViewingKey: unimplemented("\(Self.self).deriveFullViewingKey"),
        isDarkFiAddress: unimplemented("\(Self.self).isDarkFiAddress", placeholder: false)
    )
}

extension DerivationToolClient {
    public static let noOp = Self(
        deriveSpendingKey: { _, _, _ in throw "NotImplemented" },
        deriveFullViewingKey: { _, _ in throw "NotImplemented" },
        isDarkFiAddress: { _, _ in return false }
    )
}
