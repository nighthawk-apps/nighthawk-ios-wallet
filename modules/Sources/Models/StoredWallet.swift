//
//  StoredWallet.swift
//  stealth
//
//  Created by Lukáš Korba on 13.05.2022.
//

import Foundation
import Utils

/// Mnemonic language persisted in `StoredWallet`.
/// Matches legacy `MnemonicSwift.MnemonicLanguageType` Codable representation verbatim
/// so existing Keychain wallets decode identically without the external dependency.
public enum MnemonicLanguageType: Codable, Equatable, Sendable {
    case english
    case chinese
}

/// Representation of the wallet stored in the persistent storage (typically keychain, handled by `WalletStorage`).
public struct StoredWallet: Codable, Equatable {
    public let language: MnemonicLanguageType
    public let seedPhrase: SeedPhrase
    public let version: Int

    public var birthday: Birthday?

    public init(
        language: MnemonicLanguageType,
        seedPhrase: SeedPhrase,
        version: Int,
        birthday: Birthday? = nil
    ) {
        self.language = language
        self.seedPhrase = seedPhrase
        self.version = version
        self.birthday = birthday
    }
}

extension StoredWallet {
    public static let placeholder = Self(
        language: .english,
        seedPhrase: SeedPhrase(RecoveryPhrase.testPhrase.joined(separator: " ")),
        version: 0,
        birthday: Birthday(0)
    )
}
