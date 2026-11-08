//
//  DrkWalletPassStore.swift
//  stealth
//
//  Keychain-backed SQLCipher wallet_pass for DarkfiWalletHandle / DrkBootstrapConfig.
//  Deterministically derived from mnemonic words using HMAC-SHA256, matching Android and Desktop.
//

import CryptoKit
import Foundation
import KeychainSwift

/// Persistent store for the DarkFi wallet encryption passphrase.
///
/// Deterministically derived from mnemonic words:
/// HMAC-SHA256("nighthawk-drk-wallet-pass-v1", normalized_phrase) -> Base64
/// and stored in Keychain with `.accessibleWhenUnlockedThisDeviceOnly` and `synchronizable = false`.
public enum DrkWalletPassStore {
    private static let keychainKey = "darkfi_drk_wallet_pass"

    /// Returns the deterministic wallet pass for the given mnemonic words, caching in Keychain.
    public static func forMnemonic(words: [String]) -> String {
        let normalized = words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let key = SymmetricKey(data: Data("nighthawk-drk-wallet-pass-v1".utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(normalized.utf8), using: key)
        let pass = Data(mac).base64EncodedString()

        let keychain = KeychainSwift()
        keychain.accessGroup = nil
        keychain.synchronizable = false
        keychain.set(
            pass,
            forKey: keychainKey,
            withAccess: .accessibleWhenUnlockedThisDeviceOnly
        )
        return pass
    }

    /// Returns the existing wallet pass, or derives/loads from Keychain.
    public static func getOrCreate() -> String {
        let keychain = KeychainSwift()
        keychain.accessGroup = nil
        keychain.synchronizable = false

        if let existing = keychain.get(keychainKey), !existing.isEmpty {
            return existing
        }

        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed for wallet pass")

        let generated = Data(bytes).base64EncodedString()
        keychain.set(
            generated,
            forKey: keychainKey,
            withAccess: .accessibleWhenUnlockedThisDeviceOnly
        )
        return generated
    }

    /// Remove the stored SQLCipher wallet passphrase.
    public static func clear() {
        let keychain = KeychainSwift()
        keychain.accessGroup = nil
        keychain.synchronizable = false
        keychain.delete(keychainKey)
    }
}
