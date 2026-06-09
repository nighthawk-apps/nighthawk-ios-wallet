//
//  DerivationToolTestKey.swift
//  stealth
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay
import Utils

extension DerivationToolClient: TestDependencyKey {
    public static let testValue = Self(
        deriveSpendingKey: unimplemented("\(Self.self).deriveSpendingKey"),
        deriveUnifiedFullViewingKey: unimplemented("\(Self.self).deriveUnifiedFullViewingKey"),
        isUnifiedAddress: unimplemented("\(Self.self).isUnifiedAddress", placeholder: false),
        isSaplingAddress: unimplemented("\(Self.self).isSaplingAddress", placeholder: false),
        isTransparentAddress: unimplemented("\(Self.self).isTransparentAddress", placeholder: false),
        isDarkFiAddress: unimplemented("\(Self.self).isDarkFiAddress", placeholder: false)
    )
}

extension DerivationToolClient {
    public static let noOp = Self(
        deriveSpendingKey: { _, _, _ in throw "NotImplemented" },
        deriveUnifiedFullViewingKey: { _, _ in throw "NotImplemented" },
        isUnifiedAddress: { _, _ in return false },
        isSaplingAddress: { _, _ in return false },
        isTransparentAddress: { _, _ in return false },
        isDarkFiAddress: { _, _ in return false }
    )
}
