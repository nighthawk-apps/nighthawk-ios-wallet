//
//  SecurityPinStore.swift
//  Models
//
//  Keychain-backed 6-digit App PIN lock using PBKDF2-HMAC-SHA256 with a random 16-byte salt.
//  Failed attempts live in a second Keychain item (not UserDefaults). After 5 failures the PIN
//  locks for 30 seconds, then doubles, capped at 15 minutes. A successful check clears the counter.
//

import CommonCrypto
import Foundation
import Security

public enum SecurityPinStore {
    public static let pinLength = 6
    public static let pbkdf2Iterations: UInt32 = 100_000
    public static let maxFailedAttempts = 5
    public static let initialLockoutSeconds = 30
    public static let maxLockoutSeconds = 15 * 60
    public static let defaultKeychainService = "com.nighthawkapps.darkfi.securityPin"
    public static let defaultKeychainAccount = "app_pin_pbkdf2_v1"

    public enum PinVerification: Equatable {
        case success
        case failure
        case lockedOut(retryAfterSeconds: Int)
    }

    private struct StoredPinRecord: Codable {
        let salt: Data
        let hash: Data
        let iterations: UInt32
    }

    private struct PinLockoutRecord: Codable {
        var failureCount: Int
        var lockedUntil: TimeInterval?
        var lastLockoutSeconds: Int
    }

    private enum LockoutRead {
        case empty
        case record(PinLockoutRecord)
        case unavailable
    }

    private enum LockoutState {
        case open(PinLockoutRecord?)
        case locked(retryAfterSeconds: Int)
        case unavailable
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
        guard KeychainGenericPassword.upsert(service: service, account: account, data: data) == errSecSuccess else {
            return false
        }
        clearLockout(service: service, account: account)
        return true
    }

    public static func verifyPin(
        _ pin: String,
        service: String = defaultKeychainService,
        account: String = defaultKeychainAccount,
        now: Date = Date()
    ) -> PinVerification {
        guard isValidPinFormat(pin) else { return .failure }
        switch loadLockout(service: service, account: account, now: now) {
        case .unavailable:
            return .lockedOut(retryAfterSeconds: initialLockoutSeconds)
        case let .locked(retryAfterSeconds):
            return .lockedOut(retryAfterSeconds: retryAfterSeconds)
        case let .open(record):
            return verifyOpenPin(
                pin,
                existingLockout: record,
                service: service,
                account: account,
                now: now
            )
        }
    }

    /// Short countdown fragment for the lockout error already shown by Splash and Security.
    public static func lockoutCountdown(seconds: Int) -> String {
        let bounded = max(seconds, 1)
        if bounded == 1 {
            return "1 second"
        }
        if bounded < 60 {
            return "\(bounded) seconds"
        }
        let minutes = (bounded + 59) / 60
        if minutes == 1 {
            return "1 minute"
        }
        return "\(minutes) minutes"
    }

    public static func clearPin(
        service: String = defaultKeychainService,
        account: String = defaultKeychainAccount
    ) {
        deleteItem(service: service, account: account)
        clearLockout(service: service, account: account)
    }
}

private extension SecurityPinStore {
    private static func verifyOpenPin(
        _ pin: String,
        existingLockout: PinLockoutRecord?,
        service: String,
        account: String,
        now: Date
    ) -> PinVerification {
        guard let record = readRecord(service: service, account: account),
              let derived = deriveKey(pin: pin, salt: record.salt, iterations: record.iterations) else {
            return .failure
        }
        if constantTimeEqual(derived, record.hash) {
            clearLockout(service: service, account: account)
            return .success
        }
        return recordFailure(
            existing: existingLockout,
            service: service,
            account: account,
            now: now
        )
    }

    private static func recordFailure(
        existing: PinLockoutRecord?,
        service: String,
        account: String,
        now: Date
    ) -> PinVerification {
        var next = existing ?? PinLockoutRecord(failureCount: 0, lockedUntil: nil, lastLockoutSeconds: 0)
        if next.failureCount < 0 {
            next.failureCount = 0
        }
        next.failureCount += 1
        let lockedFor = lockoutDurationIfNeeded(&next, now: now)
        guard storeLockout(next, service: service, account: account) else {
            if let lockedFor {
                return .lockedOut(retryAfterSeconds: lockedFor)
            }
            return .failure
        }
        if let lockedFor {
            return .lockedOut(retryAfterSeconds: lockedFor)
        }
        return .failure
    }

    private static func lockoutDurationIfNeeded(_ record: inout PinLockoutRecord, now: Date) -> Int? {
        guard record.failureCount >= maxFailedAttempts else {
            record.lockedUntil = nil
            return nil
        }
        let duration = nextLockoutSeconds(after: record.lastLockoutSeconds)
        record.lastLockoutSeconds = duration
        record.lockedUntil = now.timeIntervalSince1970 + TimeInterval(duration)
        return duration
    }

    private static func nextLockoutSeconds(after previous: Int) -> Int {
        let doubled = previous > 0 ? previous * 2 : initialLockoutSeconds
        if doubled > maxLockoutSeconds {
            return maxLockoutSeconds
        }
        if doubled < initialLockoutSeconds {
            return initialLockoutSeconds
        }
        return doubled
    }

    private static func loadLockout(service: String, account: String, now: Date) -> LockoutState {
        switch readLockoutRecord(service: service, account: account) {
        case .unavailable:
            return .unavailable
        case .empty:
            return .open(nil)
        case let .record(record):
            guard let until = record.lockedUntil else {
                return .open(record)
            }
            let remaining = until - now.timeIntervalSince1970
            guard remaining > 0 else {
                return .open(record)
            }
            return .locked(retryAfterSeconds: max(Int(remaining.rounded(.up)), 1))
        }
    }

    private static func readLockoutRecord(service: String, account: String) -> LockoutRead {
        let (status, data) = copyKeychainItem(service: service, account: lockoutAccount(for: account))
        if status == errSecItemNotFound {
            return .empty
        }
        guard status == errSecSuccess, let data else {
            return .unavailable
        }
        guard let record = try? JSONDecoder().decode(PinLockoutRecord.self, from: data) else {
            return .empty
        }
        return .record(record)
    }

    private static func storeLockout(_ record: PinLockoutRecord, service: String, account: String) -> Bool {
        guard let data = try? JSONEncoder().encode(record) else { return false }
        return KeychainGenericPassword.upsert(
            service: service,
            account: lockoutAccount(for: account),
            data: data
        ) == errSecSuccess
    }

    private static func clearLockout(service: String, account: String) {
        deleteItem(service: service, account: lockoutAccount(for: account))
    }

    private static func lockoutAccount(for account: String) -> String {
        "\(account).lockout"
    }

    private static func readRecord(service: String, account: String) -> StoredPinRecord? {
        let (status, data) = copyKeychainItem(service: service, account: account)
        guard status == errSecSuccess,
              let data,
              let record = try? JSONDecoder().decode(StoredPinRecord.self, from: data),
              record.salt.count == 16,
              record.hash.count == 32 else {
            return nil
        }
        return record
    }

    private static func copyKeychainItem(service: String, account: String) -> (OSStatus, Data?) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return (status, item as? Data)
    }

    private static func deleteItem(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
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
