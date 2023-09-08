//
//  WalletStorage.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 03/10/2022.
//

import Foundation
import KeychainSwift
import MnemonicSwift
import ZcashLightClientKit
import Utils
import SecItem
import Models

/// Zcash implementation of the keychain that is not universal but designed to deliver functionality needed by the wallet itself.
/// All the APIs should be thread safe according to official doc:
/// https://developer.apple.com/documentation/security/certificate_key_and_trust_services/working_with_concurrency?language=objc
public struct WalletStorage {
    public enum Constants {
        public static let zcashStoredWallet = "zcashStoredWallet"
        
        public static let zcashLegacyPhrase = "zECCWalletPhrase"
        public static let zcashLegacyBirthday = "zECCWalletBirthday"
        public static let zcashLegacyKeys = "zECCWalletKeys"
        public static let zcashLegacySeedKey = "zEECWalletSeedKey"
        /// Versioning of the stored data
        public static let zcashKeychainVersion = 1
    }

    public enum KeychainError: Error, Equatable {
        case decoding
        case duplicate
        case encoding
        case noDataFound
        case unknown(OSStatus)
    }

    public enum WalletStorageError: Error {
        case alreadyImported
        case uninitializedWallet
        case storageError(Error)
        case unsupportedVersion(Int)
        case unsupportedLanguage(MnemonicLanguageType)
    }

    private let secItem: SecItemClient
    public var zcashStoredWalletPrefix = ""
    private let keychain = KeychainSwift()
    
    public init(secItem: SecItemClient) {
        self.secItem = secItem
    }

    public func importWallet(
        bip39 phrase: String,
        birthday: BlockHeight?,
        language: MnemonicLanguageType = .english
    ) throws {
        // Future-proof of the bundle to potentially avoid migration. We enforce english mnemonic.
        guard language == .english else {
            throw WalletStorageError.unsupportedLanguage(language)
        }

        let wallet = StoredWallet(
            language: language,
            seedPhrase: SeedPhrase(phrase),
            version: Constants.zcashKeychainVersion,
            birthday: Birthday(birthday)
        )

        do {
            guard let data = try encode(object: wallet) else {
                throw KeychainError.encoding
            }
            
            try setData(data, forKey: Constants.zcashStoredWallet)
        } catch KeychainError.duplicate {
            throw WalletStorageError.alreadyImported
        } catch {
            throw WalletStorageError.storageError(error)
        }
    }
    
    public func exportWallet() throws -> StoredWallet {
        guard let data = data(forKey: Constants.zcashStoredWallet) else {
            throw WalletStorageError.uninitializedWallet
        }
        
        guard let wallet = try decode(json: data, as: StoredWallet.self) else {
            throw WalletStorageError.uninitializedWallet
        }
        
        guard wallet.version == Constants.zcashKeychainVersion else {
            throw WalletStorageError.unsupportedVersion(wallet.version)
        }
        
        return wallet
    }
    
    public func areKeysPresent() throws -> Bool {
        do {
            _ = try exportWallet()
        } catch {
            throw error
        }
        
        return true
    }
    
    public func areLegacyKeysPresent() -> Bool {
        let phrase = keychain.get(Constants.zcashLegacyPhrase)
        let birthday = keychain.get(Constants.zcashLegacyBirthday)
        return phrase != nil && birthday != nil
    }
    
    public func exportLegacyPhrase() throws -> String {
        guard let seed = keychain.get(Constants.zcashLegacyPhrase) else { throw WalletStorageError.uninitializedWallet }
        return seed
    }
    
    public func exportLegacyBirthday() throws -> BlockHeight {
        guard let birthday = keychain.get(Constants.zcashLegacyBirthday),
            let value = BlockHeight(birthday) else {
                throw WalletStorageError.uninitializedWallet
        }
        return value
    }
    
    public func updateBirthday(_ height: BlockHeight) throws {
        do {
            var wallet = try exportWallet()
            wallet.birthday = Birthday(height)
            
            guard let data = try encode(object: wallet) else {
                throw KeychainError.encoding
            }
            
            try updateData(data, forKey: Constants.zcashStoredWallet)
        } catch {
            throw error
        }
    }
    
    public func nukeWallet() {
        deleteData(forKey: Constants.zcashStoredWallet)
    }
    
    public func nukeLegacyWallet() {
        keychain.delete(Constants.zcashLegacyKeys)
        keychain.delete(Constants.zcashLegacySeedKey)
        keychain.delete(Constants.zcashLegacyPhrase)
        keychain.delete(Constants.zcashLegacyBirthday)
        
        // Fix: retrocompatibility with old wallets, previous to IVK Synchronizer updates
        removeRetrocompatibilityKeys()
    }

    /**
     Removes all remaining keys related to this App except the ones considered "New" under the key `Constants.zcashStoredWallet`
     If there are no retrocompatibility keys present this function will do nothing.
    */
    private func removeRetrocompatibilityKeys() {
        let allKeys = Set(keychain.allKeys)
        // BUGFIX: avoid calling `keychain.delete("")` because it apparently wipes the keychain
        let allButNew = allKeys.subtracting([Constants.zcashStoredWallet, ""])
        for key in allButNew {
            keychain.delete(key)
        }
    }
    
    // MARK: - Wallet Storage Codable & Query helpers
    
    public func decode<T: Decodable>(json: Data, as clazz: T.Type) throws -> T? {
        do {
            let decoder = JSONDecoder()
            let data = try decoder.decode(T.self, from: json)
            return data
        } catch {
            throw KeychainError.decoding
        }
    }

    public func encode<T: Codable>(object: T) throws -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(object)
        } catch {
            throw KeychainError.encoding
        }
    }
    
    public func baseQuery(forAccount account: String = "", andKey forKey: String) -> [String: Any] {
        let query: [String: AnyObject] = [
            /// Uniquely identify this keychain accessor
            kSecAttrService as String: (zcashStoredWalletPrefix + forKey) as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword,
            /// The data in the keychain item can be accessed only while the device is unlocked by the user.
            /// This is recommended for items that need to be accessible only while the application is in the foreground.
            /// Items with this attribute do not migrate to a new device.
            /// Thus, after restoring from a backup of a different device, these items will not be present.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        return query
    }
    
    public func restoreQuery(forAccount account: String = "", andKey forKey: String) -> [String: Any] {
        var query = baseQuery(forAccount: account, andKey: forKey)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecReturnRef as String] = kCFBooleanFalse
        query[kSecReturnPersistentRef as String] = kCFBooleanFalse
        query[kSecReturnAttributes as String] = kCFBooleanFalse
        
        return query
    }

    /// Restore data for key
    public func data(
        forKey: String,
        account: String = ""
    ) -> Data? {
        let query = restoreQuery(forAccount: account, andKey: forKey)

        var result: AnyObject?
        let status = secItem.copyMatching(query as CFDictionary, &result)
        
        return result as? Data
    }
    
    /// Use carefully:  Deletes data for key
    @discardableResult
    public func deleteData(
        forKey: String,
        account: String = ""
    ) -> Bool {
        let query = baseQuery(forAccount: account, andKey: forKey)

        let status = secItem.delete(query as CFDictionary)

        return status == noErr
    }
    
    /// Store data for key
    public func setData(
        _ data: Data,
        forKey: String,
        account: String = ""
    ) throws {
        var query = baseQuery(forAccount: account, andKey: forKey)
        query[kSecValueData as String] = data as AnyObject

        var result: AnyObject?
        let status = secItem.add(query as CFDictionary, &result)
        
        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicate
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    /// Use carefully:  Update data for key
    public func updateData(
        _ data: Data,
        forKey: String,
        account: String = ""
    ) throws {
        let query = baseQuery(forAccount: account, andKey: forKey)
        
        let attributes: [String: AnyObject] = [
            kSecValueData as String: data as AnyObject
        ]

        let status = secItem.update(query as CFDictionary, attributes as CFDictionary)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.noDataFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
}
