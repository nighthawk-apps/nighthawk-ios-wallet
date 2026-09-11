//
//  WalletStorage.swift
//  stealth
//
//  Created by Lukáš Korba on 03/10/2022.
//

import Foundation
import KeychainSwift
import MnemonicSwift
import Utils
import SecItem
import Models

/// DarkFi wallet keychain storage.
/// All the APIs should be thread safe according to official doc:
/// https://developer.apple.com/documentation/security/certificate_key_and_trust_services/working_with_concurrency?language=objc
public struct WalletStorage {
    public enum Constants {
        /// Primary wallet storage key
        public static let darkfiStoredWallet = "darkfiStoredWallet"
        /// Versioning of the stored data
        public static let darkfiKeychainVersion = 1
    }

    public enum KeychainError: Error, Equatable, LocalizedError {
        case decoding
        case duplicate
        case encoding
        case noDataFound
        case unknown(OSStatus)

        public var errorDescription: String? {
            switch self {
            case .decoding:
                return "Keychain data could not be decoded."
            case .duplicate:
                return "Keychain item already exists."
            case .encoding:
                return "Wallet could not be encoded for the Keychain."
            case .noDataFound:
                return "Keychain item not found."
            case .unknown(let status):
                return "Keychain OSStatus \(status)."
            }
        }
    }

    public enum WalletStorageError: Error, LocalizedError {
        case alreadyImported
        case uninitializedWallet
        case storageError(Error)
        case unsupportedVersion(Int)
        case unsupportedLanguage(MnemonicLanguageType)

        public var errorDescription: String? {
            switch self {
            case .alreadyImported:
                return "A wallet already exists in the Keychain. Delete it, then try Create Wallet again."
            case .uninitializedWallet:
                return "No wallet found in the Keychain."
            case .storageError(let error):
                return "Keychain storage error: \(error.localizedDescription)"
            case .unsupportedVersion(let version):
                return "Unsupported wallet storage version \(version)."
            case .unsupportedLanguage(let language):
                return "Unsupported mnemonic language \(language)."
            }
        }
    }

    private let secItem: SecItemClient
    public var darkfiStoredWalletPrefix = ""
    private let keychain = KeychainSwift()

    public init(secItem: SecItemClient) {
        self.secItem = secItem
    }

    public func importWallet(
        bip39 phrase: String,
        birthday: BlockHeight?,
        language: MnemonicLanguageType = .english
    ) throws {
        // DarkFi uses 22-word seed phrases
        guard language == .english else {
            throw WalletStorageError.unsupportedLanguage(language)
        }

        let wallet = StoredWallet(
            language: language,
            seedPhrase: SeedPhrase(phrase),
            version: Constants.darkfiKeychainVersion,
            birthday: Birthday(birthday)
        )

        do {
            guard let data = try encode(object: wallet) else {
                throw KeychainError.encoding
            }

            try replaceData(data, forKey: Constants.darkfiStoredWallet)
        } catch let error as WalletStorageError {
            throw error
        } catch KeychainError.noDataFound {
            throw WalletStorageError.alreadyImported
        } catch {
            throw WalletStorageError.storageError(error)
        }
    }

    public func exportWallet() throws -> StoredWallet {
        guard let data = data(forKey: Constants.darkfiStoredWallet) else {
            throw WalletStorageError.uninitializedWallet
        }

        guard let wallet = try decode(json: data, as: StoredWallet.self) else {
            throw WalletStorageError.uninitializedWallet
        }

        guard wallet.version == Constants.darkfiKeychainVersion else {
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

    public func updateBirthday(_ height: BlockHeight) throws {
        do {
            var wallet = try exportWallet()
            wallet.birthday = Birthday(height)

            guard let data = try encode(object: wallet) else {
                throw KeychainError.encoding
            }

            try updateData(data, forKey: Constants.darkfiStoredWallet)
        } catch {
            throw error
        }
    }

    public func deleteWallet() {
        deleteData(forKey: Constants.darkfiStoredWallet)
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

    /// Match keys for copy/update/delete. Must **not** include `kSecAttrAccessible`:
    /// that attribute is write-only. Putting it in a search query makes SecItemCopyMatching
    /// and SecItemDelete miss items that SecItemAdd still treats as duplicates (error 0 /
    /// `alreadyImported` on Create Wallet, especially in the Simulator after reinstall).
    public func baseQuery(forAccount account: String = "", andKey forKey: String) -> [String: Any] {
        [
            /// Uniquely identify this keychain accessor
            kSecAttrService as String: (darkfiStoredWalletPrefix + forKey) as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword,
        ]
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
        _ = secItem.copyMatching(query as CFDictionary, &result)

        if let data = result as? Data {
            return data
        }
        #if targetEnvironment(simulator)
        return readSimulatorWallet(forKey: forKey)
        #else
        return nil
        #endif
    }

    /// Use carefully:  Deletes data for key
    @discardableResult
    public func deleteData(
        forKey: String,
        account: String = ""
    ) -> Bool {
        let query = baseQuery(forAccount: account, andKey: forKey)

        let status = secItem.delete(query as CFDictionary)
        #if targetEnvironment(simulator)
        deleteSimulatorWallet(forKey: forKey)
        #endif

        return status == noErr
    }

    /// Store data for key
    public func setData(
        _ data: Data,
        forKey: String,
        account: String = ""
    ) throws {
        try addData(data, forKey: forKey, account: account, accessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
    }

    /// Delete any leftover item, then add. Simulator reinstalls often leave a
    /// generic-password that `SecItemAdd` treats as duplicate while `SecItemUpdate`
    /// cannot see it (accessibility / access-group mismatch).
    public func replaceData(
        _ data: Data,
        forKey: String,
        account: String = ""
    ) throws {
        deleteData(forKey: forKey, account: account)
        do {
            try addData(data, forKey: forKey, account: account, accessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        } catch KeychainError.duplicate {
            do {
                try updateData(data, forKey: forKey, account: account)
            } catch {
                deleteData(forKey: forKey, account: account)
                // Unsigned Simulator builds sometimes reject ThisDeviceOnly.
                try addData(data, forKey: forKey, account: account, accessible: kSecAttrAccessibleAfterFirstUnlock)
            }
        }
    }

    private func addData(
        _ data: Data,
        forKey: String,
        account: String,
        accessible: CFString
    ) throws {
        var query = baseQuery(forAccount: account, andKey: forKey)
        /// Accessibility is set only on add — not on search/delete (see `baseQuery`).
        query[kSecAttrAccessible as String] = accessible
        query[kSecValueData as String] = data

        var result: AnyObject?
        let status = secItem.add(query as CFDictionary, &result)

        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicate
        }

        guard status == errSecSuccess else {
            #if targetEnvironment(simulator)
            // Unsigned Simulator installs (`CODE_SIGNING_ALLOWED=NO`) cannot
            // use the Keychain: SecItemAdd returns errSecMissingEntitlement (-34018).
            if status == errSecMissingEntitlement {
                try writeSimulatorWallet(data, forKey: forKey)
                return
            }
            #endif
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

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = secItem.update(query as CFDictionary, attributes as CFDictionary)

        guard status != errSecItemNotFound else {
            throw KeychainError.noDataFound
        }

        guard status == errSecSuccess else {
            #if targetEnvironment(simulator)
            if status == errSecMissingEntitlement {
                try writeSimulatorWallet(data, forKey: forKey)
                return
            }
            #endif
            throw KeychainError.unknown(status)
        }
    }

    #if targetEnvironment(simulator)
    /// File-backed wallet JSON when the Simulator Keychain is unusable.
    private func simulatorWalletFileURL(forKey key: String) throws -> URL {
        let dir = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("darkfi_simulator_keychain", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(key)
    }

    private func writeSimulatorWallet(_ data: Data, forKey key: String) throws {
        try data.write(to: try simulatorWalletFileURL(forKey: key), options: .atomic)
    }

    private func readSimulatorWallet(forKey key: String) -> Data? {
        guard let url = try? simulatorWalletFileURL(forKey: key) else { return nil }
        return try? Data(contentsOf: url)
    }

    private func deleteSimulatorWallet(forKey key: String) {
        guard let url = try? simulatorWalletFileURL(forKey: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }
    #endif
}
