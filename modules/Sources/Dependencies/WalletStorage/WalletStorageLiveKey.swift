//
//  WalletStorageLiveKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 15.11.2022.
//

import ComposableArchitecture
import Foundation
import MnemonicSwift
import SecItem
import ZcashLightClientKit

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
                walletStorage.areLegacyKeysPresent()
            },
            exportLegacyPhrase: {
                try walletStorage.exportLegacyPhrase()
            },
            exportLegacyBirthday: {
                try walletStorage.exportLegacyBirthday()
            },
            updateBirthday: { birthday in
                try walletStorage.updateBirthday(birthday)
            },
            deleteWallet: {
                walletStorage.deleteWallet()
            },
            deleteLegacyWallet: {
                walletStorage.deleteLegacyWallet()
            }
        )
    }
}
