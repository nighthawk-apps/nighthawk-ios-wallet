//
//  ChatEncryptedFileStore.swift
//  Home
//
//  Encrypts chat JSON payloads on disk using AES-GCM (256-bit) with a
//  Keychain-backed device-only key, handles one-time migration from legacy
//  plaintext .json files (with zero-overwrite scrub + deletion), and runs
//  disk I/O off the main thread on a dedicated serial queue.
//

import CryptoKit
import Foundation
import Models
import Security

enum ChatEncryptedFileStore {
    private static let keychainService = "com.nighthawkapps.darkfi.chatDiskKey"
    private static let keychainAccount = "chat_disk_aes256_key_v1"

    private static let keyLock = NSLock()
    private static var cachedKey: SymmetricKey?

    static let diskQueue = DispatchQueue(
        label: "com.nighthawkapps.chat.encryptedDisk",
        qos: .utility
    )

    /// Load decrypted JSON bytes from `encryptedURL`, migrating and scrubbing
    /// `legacyPlaintextURL` if it exists.
    static func load(encryptedURL: URL, legacyPlaintextURL: URL) -> Data? {
        diskQueue.sync {
            loadUnlocked(encryptedURL: encryptedURL, legacyPlaintextURL: legacyPlaintextURL)
        }
    }

    /// Encrypt and atomically write JSON bytes to `encryptedURL` off the main thread.
    static func saveAsync(_ plaintext: Data, encryptedURL: URL, legacyPlaintextURL: URL? = nil) {
        diskQueue.async {
            saveUnlocked(plaintext, encryptedURL: encryptedURL, legacyPlaintextURL: legacyPlaintextURL)
        }
    }

    /// Encrypt and atomically write JSON bytes on `diskQueue` synchronously (safe when called from actors/background).
    static func saveSync(_ plaintext: Data, encryptedURL: URL, legacyPlaintextURL: URL? = nil) {
        diskQueue.sync {
            saveUnlocked(plaintext, encryptedURL: encryptedURL, legacyPlaintextURL: legacyPlaintextURL)
        }
    }

    /// Remove both encrypted and legacy plaintext files safely.
    static func remove(encryptedURL: URL, legacyPlaintextURL: URL) {
        diskQueue.sync {
            scrubAndRemove(legacyPlaintextURL)
            scrubAndRemove(encryptedURL)
        }
    }

    /// Delete the Keychain AES-256 disk key (e.g. full wallet wipe).
    static func clearKey() {
        keyLock.lock()
        cachedKey = nil
        keyLock.unlock()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Derive the sibling `.enc` URL for a given `.json` URL.
    static func encryptedURL(forLegacyJSON url: URL) -> URL {
        url.deletingPathExtension().appendingPathExtension("enc")
    }

    // MARK: - Private (diskQueue)

    private static func loadUnlocked(encryptedURL: URL, legacyPlaintextURL: URL) -> Data? {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: encryptedURL.path),
           let sealedData = try? Data(contentsOf: encryptedURL),
           let key = loadOrCreateKey(),
           let decrypted = decrypt(sealedData, with: key) {
            if fileManager.fileExists(atPath: legacyPlaintextURL.path) {
                scrubAndRemove(legacyPlaintextURL)
            }
            return decrypted
        }

        // One-time migration from legacy plaintext JSON.
        guard fileManager.fileExists(atPath: legacyPlaintextURL.path),
              let plaintext = try? Data(contentsOf: legacyPlaintextURL) else {
            return nil
        }

        if saveUnlocked(plaintext, encryptedURL: encryptedURL, legacyPlaintextURL: nil) {
            scrubAndRemove(legacyPlaintextURL)
        }
        return plaintext
    }

    @discardableResult
    private static func saveUnlocked(
        _ plaintext: Data,
        encryptedURL: URL,
        legacyPlaintextURL: URL?
    ) -> Bool {
        guard let key = loadOrCreateKey(),
              let sealed = encrypt(plaintext, with: key) else {
            return false
        }
        let dir = encryptedURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        excludeFromBackup(dir)
        do {
            try sealed.write(to: encryptedURL, options: [.atomic, .completeFileProtection])
            excludeFromBackup(encryptedURL)
            if let legacyPlaintextURL, FileManager.default.fileExists(atPath: legacyPlaintextURL.path) {
                scrubAndRemove(legacyPlaintextURL)
            }
            return true
        } catch {
            return false
        }
    }

    private static func encrypt(_ plaintext: Data, with key: SymmetricKey) -> Data? {
        guard let box = try? AES.GCM.seal(plaintext, using: key) else { return nil }
        return box.combined
    }

    private static func decrypt(_ combined: Data, with key: SymmetricKey) -> Data? {
        guard let box = try? AES.GCM.SealedBox(combined: combined) else { return nil }
        return try? AES.GCM.open(box, using: key)
    }

    private static func loadOrCreateKey() -> SymmetricKey? {
        keyLock.lock()
        defer { keyLock.unlock() }
        if let cachedKey {
            return cachedKey
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data, data.count == 32 {
            let key = SymmetricKey(data: data)
            cachedKey = key
            return key
        }
        if status == errSecInteractionNotAllowed {
            return nil
        }

        var bytes = [UInt8](repeating: 0, count: 32)
        let rngStatus = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard rngStatus == errSecSuccess else { return nil }
        let keyData = Data(bytes)
        _ = KeychainGenericPassword.upsert(
            service: keychainService,
            account: keychainAccount,
            data: keyData
        )
        let key = SymmetricKey(data: keyData)
        cachedKey = key
        return key
    }

    private static func scrubAndRemove(_ url: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else { return }
        if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int, size > 0 {
            let zeros = Data(repeating: 0, count: size)
            try? zeros.write(to: url, options: .atomic)
        }
        try? fileManager.removeItem(at: url)
    }

    private static func excludeFromBackup(_ url: URL) {
        var mutable = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? mutable.setResourceValues(values)
    }
}
