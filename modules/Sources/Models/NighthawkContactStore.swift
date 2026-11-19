import Foundation
import Security

/// Chat identity + DM public key + wallet address. DM secrets stay in DarkircCryptoStore.
/// This record is Keychain-backed (`WhenUnlockedThisDeviceOnly`, not synced).
public enum NighthawkContactStore {
    public static let keychainService = "com.nighthawkapps.darkfi.nighthawkContacts"
    public static let keychainAccount = "nighthawk_contacts_v1"
    public static let maxEntries = 200

    public static func load() -> [NighthawkContact] {
        guard let data = readFromKeychain(),
              let decoded = try? JSONDecoder().decode([Stored].self, from: data) else {
            return []
        }
        return decoded.map(\.contact).filter { !$0.nickname.isEmpty && !$0.dmPublicKey.isEmpty }
    }

    public static func find(id: String) -> NighthawkContact? {
        let key = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return load().first { $0.id == key }
    }

    public static func findByNick(_ nick: String) -> NighthawkContact? {
        find(id: nick.lowercased())
    }

    @discardableResult
    public static func upsert(_ contact: NighthawkContact) -> [NighthawkContact] {
        let nick = contact.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let dm = contact.dmPublicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nick.isEmpty, !dm.isEmpty else { return load() }
        let id = nick.lowercased()
        var next = load().filter { $0.id != id }
        next.insert(
            NighthawkContact(id: id, nickname: nick, dmPublicKey: dm, walletAddress: contact.walletAddress),
            at: 0
        )
        next = Array(next.prefix(maxEntries))
        save(next)
        return next
    }

    public static func remove(nick: String) {
        let id = nick.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let next = load().filter { $0.id != id }
        save(next)
    }

    private struct Stored: Codable {
        var id: String
        var nickname: String
        var dmPublicKey: String
        var walletAddress: String?

        var contact: NighthawkContact {
            NighthawkContact(id: id, nickname: nickname, dmPublicKey: dmPublicKey, walletAddress: walletAddress)
        }

        init(_ contact: NighthawkContact) {
            id = contact.id
            nickname = contact.nickname
            dmPublicKey = contact.dmPublicKey
            walletAddress = contact.walletAddress
        }
    }

    private static func save(_ contacts: [NighthawkContact]) {
        let stored = contacts.map(Stored.init)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
        let updated = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if updated == errSecItemNotFound {
            var newQuery = query
            newQuery.merge(attrs) { _, new in new }
            SecItemAdd(newQuery as CFDictionary, nil)
        }
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
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }
}
