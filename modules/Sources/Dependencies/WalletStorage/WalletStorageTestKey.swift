//
//  WalletStorageTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 14.11.2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension WalletStorageClient: TestDependencyKey {
    public static let testValue = Self(
        importWallet: unimplemented("\(Self.self).importWallet"),
        exportWallet: unimplemented("\(Self.self).exportWallet", placeholder: .placeholder),
        areKeysPresent: unimplemented("\(Self.self).areKeysPresent", placeholder: false),
        areLegacyKeysPresent: unimplemented("\(Self.self).areLegacyKeysPresent", placeholder: false),
        exportLegacyPhrase: unimplemented("\(Self.self).exportLegacyPhrase"),
        exportLegacyBirthday: unimplemented("\(Self.self).exportLegacyBirthday"),
        updateBirthday: unimplemented("\(Self.self).updateBirthday"),
        deleteWallet: unimplemented("\(Self.self).deleteWallet"),
        deleteLegacyWallet: unimplemented("\(Self.self).deleteLegacyWallet")
    )
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
