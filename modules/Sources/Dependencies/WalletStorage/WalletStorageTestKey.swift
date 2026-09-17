//
//  WalletStorageTestKey.swift
//  stealth
//

import ComposableArchitecture
import XCTestDynamicOverlay
import Models
import Utils

extension WalletStorageClient: TestDependencyKey {
    public static let testValue = Self.noOp
}

extension WalletStorageClient {
    public static let noOp = Self(
        importWallet: { _, _, _ in },
        exportWallet: { .placeholder },
        areKeysPresent: { false },
        areLegacyKeysPresent: { false },
        exportLegacyPhrase: { "" },
        exportLegacyBirthday: { .zero },
        updateBirthday: { _ in },
        deleteWallet: { },
        deleteLegacyWallet: { }
    )
}
