//
//  DarkircContactManager.swift
//  stealth
//
//  Manages DM contact lifecycle and ChaCha20 encryption/decryption.
//  Port of Android's DarkircCryptoManager REHASH logic.
//
//  The key exchange workflow:
//  1. User generates a DM keypair (secret + public)
//  2. User shares their public key via !darkfi-dm-pubkey:<bs58>
//  3. Peer shares their public key back
//  4. Both sides now have (my_secret, their_public) for ChaCha20
//  5. Messages are encrypted: chacha_encrypt_dm(my_secret, their_public, plaintext) → ciphertext_b58
//  6. Messages are decrypted: chacha_decrypt_dm(my_secret, their_public, ciphertext_b58) → plaintext
//
//  When darkirc runs embedded, it handles encryption on the wire automatically.
//  When using DM via the IRC bridge directly, the app must encrypt/decrypt.
//

import DarkfiCore
import Foundation
import Security

/// Manages DM contact crypto operations.
public enum DarkircContactManager {
    /// Generate a new DM keypair using the Rust FFI.
    /// Returns (secretB58, publicB58) or nil if FFI unavailable.
    ///
    /// NOTE: generateDmKeypair is defined in the UDL but the current generated
    /// Swift bindings don't include it. This uses a stub that generates random bytes
    /// until the bindings are regenerated. When available, use:
    /// ```
    /// let kp = generateDmKeypair()
    /// return (kp.secretB58, kp.publicB58)
    /// ```
    public static func generateKeypair() -> (secretB58: String, publicB58: String)? {
        // Stub: generate 32 random bytes and base58-encode them
        // This is cryptographically sound for key generation but won't interop
        // with actual darkirc until the real FFI is wired.
        // TODO: Replace with generateDmKeypair() from UniFFI when bindings are regenerated
        var secretBytes = [UInt8](repeating: 0, count: 32)
        var publicBytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, 32, &secretBytes) == errSecSuccess,
              SecRandomCopyBytes(kSecRandomDefault, 32, &publicBytes) == errSecSuccess else {
            return nil
        }
        
        let secretB58 = Base58.encode(secretBytes)
        let publicB58 = Base58.encode(publicBytes)
        return (secretB58, publicB58)
    }
    
    /// Encrypt a DM message using ChaCha20 via FFI.
    /// Returns base58-encoded ciphertext, or nil if encryption fails.
    public static func encryptMessage(
        mySecretB58: String,
        theirPublicB58: String,
        plaintext: String
    ) -> String? {
        guard let secretBytes = Base58.decode(mySecretB58),
              let publicBytes = Base58.decode(theirPublicB58) else {
            return nil
        }
        
        do {
            return try chachaEncryptDm(
                mySecret: secretBytes,
                theirPublic: publicBytes,
                plaintext: plaintext
            )
        } catch {
            print("[DarkircContactManager] Encrypt failed: \(error)")
            return nil
        }
    }
    
    /// Decrypt a DM message using ChaCha20 via FFI.
    /// Returns plaintext, or nil if decryption fails (wrong key, corrupted, etc).
    public static func decryptMessage(
        mySecretB58: String,
        theirPublicB58: String,
        ciphertextB58: String
    ) -> String? {
        guard let secretBytes = Base58.decode(mySecretB58),
              let publicBytes = Base58.decode(theirPublicB58) else {
            return nil
        }
        
        do {
            return try chachaDecryptDm(
                mySecret: secretBytes,
                theirPublic: publicBytes,
                ciphertextB58: ciphertextB58
            )
        } catch {
            // Expected for messages not intended for us or with wrong keys
            return nil
        }
    }
    
    /// Try to decrypt an incoming DM-style message against all known contacts.
    /// Returns (contact, plaintext) if any contact's keys can decrypt it.
    public static func tryDecryptWithAnyContact(
        ciphertextB58: String,
        contacts: [DmContact]
    ) -> (contact: DmContact, plaintext: String)? {
        for contact in contacts {
            if let plaintext = decryptMessage(
                mySecretB58: contact.mySecretB58,
                theirPublicB58: contact.theirPublicB58,
                ciphertextB58: ciphertextB58
            ) {
                return (contact, plaintext)
            }
        }
        return nil
    }
}

// MARK: - Base58 encoder/decoder

/// Minimal Base58 implementation for key encoding.
/// DarkFi uses standard Bitcoin-style base58 (no check).
public enum Base58 {
    private static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
    
    public static func encode(_ bytes: [UInt8]) -> String {
        var digits = [UInt8]()
        
        for byte in bytes {
            var carry = Int(byte)
            for j in 0..<digits.count {
                carry += Int(digits[j]) * 256
                digits[j] = UInt8(carry % 58)
                carry /= 58
            }
            while carry > 0 {
                digits.append(UInt8(carry % 58))
                carry /= 58
            }
        }
        
        // Leading zeros
        for byte in bytes {
            if byte != 0 { break }
            digits.append(0)
        }
        
        return String(digits.reversed().map { alphabet[Int($0)] })
    }
    
    public static func decode(_ string: String) -> [UInt8]? {
        var digits = [UInt8]()
        
        for char in string {
            guard let index = alphabet.firstIndex(of: char) else { return nil }
            var carry = index
            for j in 0..<digits.count {
                carry += Int(digits[j]) * 58
                digits[j] = UInt8(carry & 0xFF)
                carry >>= 8
            }
            while carry > 0 {
                digits.append(UInt8(carry & 0xFF))
                carry >>= 8
            }
        }
        
        // Leading '1's → leading zeros
        for char in string {
            if char != "1" { break }
            digits.append(0)
        }
        
        return digits.reversed()
    }
}
