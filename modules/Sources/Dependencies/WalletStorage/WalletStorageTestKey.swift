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
        importWallet: XCTUnimplemented("\(Self.self).importWallet"),
        exportWallet: XCTUnimplemented("\(Self.self).exportWallet", placeholder: .placeholder),
        areKeysPresent: XCTUnimplemented("\(Self.self).areKeysPresent", placeholder: false),
        areLegacyKeysPresent: XCTUnimplemented("\(Self.self).areLegacyKeysPresent", placeholder: false),
        exportLegacyPhrase: XCTUnimplemented("\(Self.self).exportLegacyPhrase"),
        exportLegacyBirthday: XCTUnimplemented("\(Self.self).exportLegacyBirthday"),
        updateBirthday: XCTUnimplemented("\(Self.self).updateBirthday"),
        deleteWallet: XCTUnimplemented("\(Self.self).deleteWallet"),
        deleteLegacyWallet: XCTUnimplemented("\(Self.self).deleteLegacyWallet")
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
