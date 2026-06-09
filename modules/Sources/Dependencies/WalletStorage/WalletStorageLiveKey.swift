//
//  WalletStorageLiveKey.swift
//  stealth
//
//  DarkFi wallet storage — no legacy Zcash migration needed.
//

import ComposableArchitecture
import Foundation
import MnemonicSwift
import SecItem
import Utils

extension WalletStorageClient: DependencyKey {
    public static let liveValue = WalletStorageClient.live()

    public static func live(walletStorage: WalletStorage = WalletStorage(secItem: .live)) -> Self {
        Self(
            importWallet: { bip39, birthday, language in
                try walletStorage.importWallet(
                    bip39: bip39,
                    birthday: birthday,
                    language: language
                )
            },
            exportWallet: {
                try walletStorage.exportWallet()
            },
            areKeysPresent: {
                try walletStorage.areKeysPresent()
            },
            areLegacyKeysPresent: {
                // DarkFi: No legacy Zcash keys to migrate
                false
            },
            exportLegacyPhrase: {
                // DarkFi: No legacy Zcash phrase
                throw WalletStorage.WalletStorageError.uninitializedWallet
            },
            exportLegacyBirthday: {
                // DarkFi: No legacy Zcash birthday
                throw WalletStorage.WalletStorageError.uninitializedWallet
            },
            updateBirthday: { birthday in
                try walletStorage.updateBirthday(birthday)
            },
            deleteWallet: {
                walletStorage.deleteWallet()
            },
            deleteLegacyWallet: {
                // DarkFi: No legacy wallet to delete — no-op
            }
        )
    }
}
