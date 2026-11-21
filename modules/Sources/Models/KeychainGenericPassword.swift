import Foundation
import Security

public enum KeychainWriteError: Error, Equatable, CustomStringConvertible {
    case encodeFailed
    case status(OSStatus)

    public var description: String {
        switch self {
        case .encodeFailed:
            return "Could not encode the Keychain item"
        case let .status(code):
            return "Keychain write failed (\(code))"
        }
    }
}

public enum KeychainGenericPassword {
    /// Insert or replace a generic-password item. Returns `errSecSuccess` or the OSStatus.
    public static func upsert(service: String, account: String, data: Data) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
        let updated = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if updated == errSecSuccess {
            return errSecSuccess
        }
        if updated == errSecItemNotFound {
            var newQuery = query
            newQuery.merge(attrs) { _, new in new }
            return SecItemAdd(newQuery as CFDictionary, nil)
        }
        return updated
    }
}
