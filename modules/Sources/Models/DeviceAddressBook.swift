import Foundation
import Security

/// Device-only labels for DarkFi addresses. Stored securely in the iOS Keychain.
public struct DeviceAddressBook: Equatable {
    public struct Entry: Equatable, Codable, Identifiable {
        public var label: String
        public var address: String
        public var id: String { address.lowercased() }

        public init(label: String, address: String) {
            self.label = label
            self.address = address
        }
    }

    public static let keychainService = "com.nighthawkapps.darkfi.addressbook"
    public static let keychainAccount = "darkfiAddressBook"
    public static let legacyDefaultsKey = "darkfiAddressBook"
    public static let maxEntries = 50

    public static func load() -> [Entry] {
        // Read from iOS Keychain
        if let data = readFromKeychain() {
            if let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
                return decoded.filter { !$0.label.isEmpty && !$0.address.isEmpty }
            }
        }
        // One-time automatic migration from legacy UserDefaults
        if let raw = UserDefaults.standard.string(forKey: legacyDefaultsKey),
           let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
            let valid = decoded.filter { !$0.label.isEmpty && !$0.address.isEmpty }
            saveToKeychain(valid)
            UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
            return valid
        }
        return []
    }

    @discardableResult
    public static func upsert(
        label: String,
        address: String
    ) -> [Entry] {
        let trimmedLabel = String(label.trimmingCharacters(in: .whitespacesAndNewlines).prefix(64))
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty, !trimmedAddress.isEmpty else {
            return load()
        }
        var next = load().filter {
            $0.address.caseInsensitiveCompare(trimmedAddress) != .orderedSame
        }
        next.insert(Entry(label: trimmedLabel, address: trimmedAddress), at: 0)
        next = Array(next.prefix(maxEntries))
        saveToKeychain(next)
        return next
    }

    private static func saveToKeychain(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        newQuery[kSecAttrSynchronizable as String] = kCFBooleanFalse
        SecItemAdd(newQuery as CFDictionary, nil)
    }

    private static func readFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return data
    }
}
