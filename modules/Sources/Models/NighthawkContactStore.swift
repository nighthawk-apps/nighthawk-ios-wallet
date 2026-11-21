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
        return decoded.map(\.contact).filter {
            let hasNick = !$0.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasDm = !$0.dmPublicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasWallet = !($0.walletAddress?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            return hasDm || hasWallet || hasNick && (hasDm || hasWallet)
        }
    }

    public static func find(id: String) -> NighthawkContact? {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        return load().first { $0.id == lower || $0.id == trimmed }
    }

    public static func findByNick(_ nick: String) -> NighthawkContact? {
        let lower = nick.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty else { return nil }
        return load().first { $0.id == lower || $0.nickname.lowercased() == lower }
    }

    public static func findByWalletAddress(_ address: String) -> NighthawkContact? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return load().first { $0.walletAddress == trimmed }
    }

    @discardableResult
    public static func upsert(_ contact: NighthawkContact, syncAddressBook: Bool = true) -> [NighthawkContact] {
        let nick = contact.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let dm = contact.dmPublicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let addr = contact.walletAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAddr = (addr?.isEmpty == false) ? addr : nil
        guard !dm.isEmpty || cleanAddr != nil else { return load() }

        let existingByAddr = cleanAddr.flatMap { findByWalletAddress($0) }
        let existingByNick = nick.isEmpty ? nil : findByNick(nick)
        let resolvedNick = !nick.isEmpty ? nick : (existingByAddr?.nickname ?? cleanAddr ?? "")
        let resolvedDm = !dm.isEmpty ? dm : (existingByNick?.dmPublicKey ?? existingByAddr?.dmPublicKey ?? "")
        let resolvedAddr = cleanAddr ?? existingByNick?.walletAddress
        let id = !resolvedNick.isEmpty ? resolvedNick.lowercased() : (resolvedAddr ?? resolvedDm)

        var next = load().filter {
            $0.id != id && (resolvedAddr == nil || $0.walletAddress != resolvedAddr)
        }
        next.insert(
            NighthawkContact(id: id, nickname: resolvedNick, dmPublicKey: resolvedDm, walletAddress: resolvedAddr),
            at: 0
        )
        next = Array(next.prefix(maxEntries))
        guard save(next) else { return load() }
        if syncAddressBook, let resolvedAddr, !resolvedNick.isEmpty {
            _ = DeviceAddressBook.upsert(label: resolvedNick, address: resolvedAddr, syncContacts: false)
        }
        return next
    }

    public static func remove(nick: String) {
        let id = nick.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let next = load().filter { $0.id != id }
        save(next)
    }

    public static func removeAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
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

    @discardableResult
    private static func save(_ contacts: [NighthawkContact]) -> Bool {
        let stored = contacts.map(Stored.init)
        guard let data = try? JSONEncoder().encode(stored) else { return false }
        return KeychainGenericPassword.upsert(
            service: keychainService,
            account: keychainAccount,
            data: data
        ) == errSecSuccess
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
