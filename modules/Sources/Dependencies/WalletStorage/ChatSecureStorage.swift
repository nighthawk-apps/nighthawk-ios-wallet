//
//  ChatSecureStorage.swift
//  stealth
//
//  Keychain-backed storage for DarkFi chat secrets.
//  Replaces the previous plaintext UserDefaults storage for DM keys
//  and encrypted channel/contact metadata.
//

import Foundation
import KeychainSwift

/// Keychain-backed store for chat-related secrets that must never
/// be stored in plaintext UserDefaults.
///
/// Stored values:
/// - DM Curve25519 secret key
/// - DM Curve25519 public key
/// - Encrypted channels JSON
/// - Encrypted contacts JSON
///
/// All values use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
/// protection (via KeychainSwift's `.accessibleWhenUnlockedThisDeviceOnly`)
/// so they do not migrate to new devices or appear in unencrypted backups.
public struct ChatSecureStorage {
    private enum Keys {
        static let dmPublicKey = "darkfi_chat_dm_pubkey"
        static let dmSecretKey = "darkfi_chat_dm_secret"
        static let encryptedChannelsJSON = "darkfi_chat_enc_channels"
        static let encryptedContactsJSON = "darkfi_chat_enc_contacts"
    }

    private let keychain: KeychainSwift

    public init() {
        let kc = KeychainSwift()
        // Prevent data from migrating to new devices or appearing
        // in unencrypted iTunes/Finder backups.
        kc.accessGroup = nil
        kc.synchronizable = false
        self.keychain = kc
    }

    // MARK: - DM Public Key

    public var dmPublicKey: String? {
        keychain.get(Keys.dmPublicKey)
    }

    public func setDmPublicKey(_ key: String?) {
        if let key {
            keychain.set(
                key,
                forKey: Keys.dmPublicKey,
                withAccess: .accessibleWhenUnlockedThisDeviceOnly
            )
        } else {
            keychain.delete(Keys.dmPublicKey)
        }
    }

    // MARK: - DM Secret Key

    public var dmSecretKey: String? {
        keychain.get(Keys.dmSecretKey)
    }

    public func setDmSecretKey(_ key: String?) {
        if let key {
            keychain.set(
                key,
                forKey: Keys.dmSecretKey,
                withAccess: .accessibleWhenUnlockedThisDeviceOnly
            )
        } else {
            keychain.delete(Keys.dmSecretKey)
        }
    }

    // MARK: - Encrypted Channels JSON

    public var encryptedChannelsJSON: String? {
        keychain.get(Keys.encryptedChannelsJSON)
    }

    public func setEncryptedChannelsJSON(_ json: String?) {
        if let json {
            keychain.set(
                json,
                forKey: Keys.encryptedChannelsJSON,
                withAccess: .accessibleWhenUnlockedThisDeviceOnly
            )
        } else {
            keychain.delete(Keys.encryptedChannelsJSON)
        }
    }

    // MARK: - Encrypted Contacts JSON

    public var encryptedContactsJSON: String? {
        keychain.get(Keys.encryptedContactsJSON)
    }

    public func setEncryptedContactsJSON(_ json: String?) {
        if let json {
            keychain.set(
                json,
                forKey: Keys.encryptedContactsJSON,
                withAccess: .accessibleWhenUnlockedThisDeviceOnly
            )
        } else {
            keychain.delete(Keys.encryptedContactsJSON)
        }
    }

    // MARK: - Wipe

    /// Removes all chat secrets from the Keychain.
    public func removeAll() {
        keychain.delete(Keys.dmPublicKey)
        keychain.delete(Keys.dmSecretKey)
        keychain.delete(Keys.encryptedChannelsJSON)
        keychain.delete(Keys.encryptedContactsJSON)
    }
}
