//
//  DrkWalletPassStore.swift
//  stealth
//
//  Keychain-backed SQLCipher wallet_pass for DarkfiWalletHandle / DrkBootstrapConfig.
//  Generated once per install (not derived from the seed).
//

import Foundation
import KeychainSwift

/// Persistent store for the DarkFi wallet encryption passphrase.
///
/// Mirrors Android `DrkWalletPassStore`: generate 32 random bytes, Base64-encode,
/// and keep them in the Keychain with `.accessibleWhenUnlockedThisDeviceOnly`.
public enum DrkWalletPassStore {
    private static let keychainKey = "darkfi_drk_wallet_pass"

    /// Returns the existing wallet pass, or generates and stores a new one.
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

    /// Remove the stored SQLCipher wallet passphrase (next open generates a new one).
    public static func clear() {
        let keychain = KeychainSwift()
        keychain.accessGroup = nil
        keychain.synchronizable = false
        keychain.delete(keychainKey)
    }
}
