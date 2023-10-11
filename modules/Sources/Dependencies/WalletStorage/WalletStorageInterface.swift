//
//  WalletStorageInterface.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 15.11.2022.
//

import ComposableArchitecture
import MnemonicSwift
import ZcashLightClientKit
import Models

extension DependencyValues {
    public var walletStorage: WalletStorageClient {
        get { self[WalletStorageClient.self] }
        set { self[WalletStorageClient.self] = newValue }
    }
}

/// The `WalletStorageClient` is a wrapper around the `WalletStorage` type that allows for easy testing.
/// The `WalletStorage` Type is comprised of static functions that take and produce data.  In order
/// to easily produce test data, all of these static functions have been wrapped in function
/// properties that live on the `WalletStorageClient` type.  Because of this, you can instantiate
/// the `WalletStorageClient` with your own implementation of these functions for testing purposes,
/// or you can use one of the built in static versions of the `WalletStorageClient`.
public struct WalletStorageClient {
    /// Store recovery phrase and optionally even birthday to the secured and persistent storage.
    /// This function creates an instance of `StoredWallet` and automatically handles versioning of the stored data.
    ///
    /// - Parameters:
    ///   - bip39: Mnemonic/Seed phrase from `MnemonicSwift`
    ///   - birthday: BlockHeight from SDK
    ///   - language: Mnemonic's language
    /// - Throws:
    ///   - `WalletStorageError.unsupportedLanguage`:  when mnemonic's language is anything other than English
    ///   - `WalletStorageError.alreadyImported` when valid wallet is already in the storage
    ///   - `WalletStorageError.storageError` when some unrecognized error occurred
    public let importWallet: (String, BlockHeight?, MnemonicLanguageType) throws -> Void

    /// Load the representation of the wallet from the persistent and secured storage.
    ///
    /// - Returns: the representation of the wallet from the persistent and secured storage.
    /// - Throws:
    ///   - `WalletStorageError.uninitializedWallet`:  when no wallet's data is found in the keychain.
    ///   - `WalletStorageError.storageError` when some unrecognized error occurred.
    ///   - `WalletStorageError.unsupportedVersion` when wallet's version stored in the keychain is outdated.
    public var exportWallet: () throws -> StoredWallet

    /// Check if the wallet representation `StoredWallet` is present in the persistent storage.
    ///
    /// - Returns: the information whether some wallet is stored or is not available
    public var areKeysPresent: () throws -> Bool
    
    /// Check if the wallet representation for the legacy wallet is present in the persistent storage.
    ///
    /// - Returns: the information whether some wallet is stored or is not available
    public var areLegacyKeysPresent: () -> Bool
    
    /// Load the legacy wallet phrase from the persistent and secured storage.
    public var exportLegacyPhrase: () throws -> String
    
    /// Load the legacy wallet birthday from the persistent and secured storage.
    public var exportLegacyBirthday: () throws -> BlockHeight

    /// Update the birthday in the securely stored wallet.
    ///
    /// - Parameters:
    ///   - birthday: BlockHeight from SDK
    /// - Throws:
    ///   - `WalletStorage.KeychainError.encoding`:  when encoding the wallet's data failed.
    ///   - `WalletStorageError.storageError` when some unrecognized error occurred.
    public let updateBirthday: (BlockHeight) throws -> Void

    /// Use carefully: deletes the stored wallet.
    /// There's no fate but what we make for ourselves - Sarah Connor.
    public let deleteWallet: () -> Void
    
    /// Use carefully: deletes the legacy stored wallet.
    /// There's no fate but what we make for ourselves - Sarah Connor.
    public let deleteLegacyWallet: () -> Void
    
    public init(
        importWallet: @escaping (String, BlockHeight?, MnemonicLanguageType) throws -> Void,
        exportWallet: @escaping () throws -> StoredWallet,
        areKeysPresent: @escaping () throws -> Bool,
        areLegacyKeysPresent: @escaping () -> Bool,
        exportLegacyPhrase: @escaping () throws -> String,
        exportLegacyBirthday: @escaping () throws -> BlockHeight,
        updateBirthday: @escaping (BlockHeight) throws -> Void,
        deleteWallet: @escaping () -> Void,
        deleteLegacyWallet: @escaping () -> Void
    ) {
        self.importWallet = importWallet
        self.exportWallet = exportWallet
        self.areKeysPresent = areKeysPresent
        self.areLegacyKeysPresent = areLegacyKeysPresent
        self.exportLegacyPhrase = exportLegacyPhrase
        self.exportLegacyBirthday = exportLegacyBirthday
        self.updateBirthday = updateBirthday
        self.deleteWallet = deleteWallet
        self.deleteLegacyWallet = deleteLegacyWallet
    }
}
