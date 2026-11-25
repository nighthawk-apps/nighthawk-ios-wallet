//
//  SecurityPinStore.swift
//  Models
//
//  Keychain-backed 6-digit App PIN lock using PBKDF2-HMAC-SHA256 with a random 16-byte salt.
//

import CommonCrypto
import Foundation
import Security

public enum SecurityPinStore {
    public static let pinLength = 6
    public static let pbkdf2Iterations: UInt32 = 100_000
    public static let defaultKeychainService = "com.nighthawkapps.darkfi.securityPin"
    public static let defaultKeychainAccount = "app_pin_pbkdf2_v1"

    private struct StoredPinRecord: Codable {
        let salt: Data
        let hash: Data
        let iterations: UInt32
    }

    public static func isValidPinFormat(_ pin: String) -> Bool {
        pin.count == pinLength && pin.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    public static func isPinSet(
        service: String = defaultKeychainService,
        account: String = defaultKeychainAccount
    ) -> Bool {
        readRecord(service: service, account: account) != nil
    }

    @discardableResult
    public static func setPin(
        _ pin: String,
        service: String = defaultKeychainService,
        account: String = defaultKeychainAccount
    ) -> Bool {
        guard isValidPinFormat(pin) else { return false }
        var saltBytes = [UInt8](repeating: 0, count: 16)
        guard SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes) == errSecSuccess else {
            return false
        }
        let salt = Data(saltBytes)
        guard let derived = deriveKey(pin: pin, salt: salt, iterations: pbkdf2Iterations) else {
            return false
        }
        let record = StoredPinRecord(salt: salt, hash: derived, iterations: pbkdf2Iterations)
        guard let data = try? JSONEncoder().encode(record) else { return false }
        return KeychainGenericPassword.upsert(service: service, account: account, data: data) == errSecSuccess
    }

    public static func verifyPin(
        _ pin: String,
        service: String = defaultKeychainService,
        account: String = defaultKeychainAccount
    ) -> Bool {
        guard isValidPinFormat(pin),
              let record = readRecord(service: service, account: account),
              let derived = deriveKey(pin: pin, salt: record.salt, iterations: record.iterations) else {
            return false
        }
        return constantTimeEqual(derived, record.hash)
    }

    public static func clearPin(
        service: String = defaultKeychainService,
        account: String = defaultKeychainAccount
    ) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func readRecord(service: String, account: String) -> StoredPinRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let record = try? JSONDecoder().decode(StoredPinRecord.self, from: data),
              record.salt.count == 16,
              record.hash.count == 32 else {
            return nil
        }
        return record
    }

    private static func deriveKey(pin: String, salt: Data, iterations: UInt32) -> Data? {
        let pinData = Data(pin.utf8)
        var derived = [UInt8](repeating: 0, count: 32)
        let result: Int32 = pinData.withUnsafeBytes { pinRaw in
            salt.withUnsafeBytes { saltRaw in
                guard let pinPtr = pinRaw.bindMemory(to: Int8.self).baseAddress,
                      let saltPtr = saltRaw.bindMemory(to: UInt8.self).baseAddress else {
                    return Int32(kCCParamError)
                }
                return CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pinPtr,
                    pinData.count,
                    saltPtr,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    iterations,
                    &derived,
                    derived.count
                )
            }
        }
        guard result == kCCSuccess else { return nil }
        return Data(derived)
    }

    private static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for (lhsByte, rhsByte) in zip(lhs, rhs) {
            diff |= (lhsByte ^ rhsByte)
        }
        return diff == 0
    }
}
