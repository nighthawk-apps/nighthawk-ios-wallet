//
//  DarkircCryptoStore.swift
//  stealth
//
//  Persists DM contact crypto configs (ChaCha20 keypairs) in the iOS Keychain.
//  Secret keys are NEVER stored in plaintext JSON files on disk.
//

import DarkfiCore
import Foundation
import Models
import Security

// MARK: - DmContact model

/// A DM contact with ChaCha20 keypair crypto configuration.
public struct DmContact: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let contactLabel: String
    public let theirPublicB58: String
    public let mySecretB58: String
    public let myPublicB58: String
    public let createdAt: Date
    public let ratchetCapable: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case contactLabel
        case theirPublicB58
        case mySecretB58
        case myPublicB58
        case createdAt
        case ratchetCapable
    }

    public init(
        id: String = UUID().uuidString,
        contactLabel: String,
        theirPublicB58: String,
        mySecretB58: String,
        myPublicB58: String,
        createdAt: Date = Date(),
        ratchetCapable: Bool = false
    ) {
        self.id = id
        self.contactLabel = contactLabel
        self.theirPublicB58 = theirPublicB58
        self.mySecretB58 = mySecretB58
        self.myPublicB58 = myPublicB58
        self.createdAt = createdAt
        self.ratchetCapable = ratchetCapable
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        contactLabel = try container.decode(String.self, forKey: .contactLabel)
        theirPublicB58 = try container.decode(String.self, forKey: .theirPublicB58)
        mySecretB58 = try container.decode(String.self, forKey: .mySecretB58)
        myPublicB58 = try container.decode(String.self, forKey: .myPublicB58)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        ratchetCapable = try container.decodeIfPresent(Bool.self, forKey: .ratchetCapable) ?? false
    }
}

// MARK: - DmConversation metadata

/// Tracks DM conversation state: last message, unread count, etc.
public struct DmConversation: Codable, Equatable, Identifiable, Sendable {
    public let id: String // matches DmContact.id
    public let contactLabel: String
    public var lastMessageText: String?
    public var lastMessageAt: Date?
    public var unreadCount: Int

    public init(
        id: String,
        contactLabel: String,
        lastMessageText: String? = nil,
        lastMessageAt: Date? = nil,
        unreadCount: Int = 0
    ) {
        self.id = id
        self.contactLabel = contactLabel
        self.lastMessageText = lastMessageText
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
    }
}

// MARK: - DarkircCryptoStore

/// Manages persistence of DM contacts (Keychain-backed) and conversation metadata.
/// Thread-safe via actor isolation.
public actor DarkircCryptoStore {
    public static let shared = DarkircCryptoStore()

    public static let defaultKeychainService = "com.nighthawkapps.darkfi.dmContacts"
    public static let defaultKeychainAccount = "dm_contacts_v1"

    private var contacts: [DmContact] = []
    private var conversations: [DmConversation] = []
    private var loaded = false

    private let customStorageDir: URL?
    private let customDatastoreDir: URL?
    private let keychainService: String
    private let keychainAccount: String

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    public init(
        storageDirectory: URL? = nil,
        datastoreDirectory: URL? = nil,
        keychainService: String = DarkircCryptoStore.defaultKeychainService,
        keychainAccount: String = DarkircCryptoStore.defaultKeychainAccount
    ) {
        self.customStorageDir = storageDirectory
        self.customDatastoreDir = datastoreDirectory
        self.keychainService = keychainService
        self.keychainAccount = keychainAccount
    }

    // MARK: - Contact CRUD

    /// All DM contacts.
    public func allContacts() -> [DmContact] {
        ensureLoaded()
        return contacts
    }

    /// Register every stored DM contact into Rust `DM_CONTACTS` in-memory map.
    public func registerAllWithRust() {
        ensureLoaded()
        clearDmContacts()
        for contact in contacts {
            _ = registerInRust(contact)
        }
    }

    /// Add a new DM contact. Returns the saved contact.
    /// Throws when the keys are unusable or the Keychain write fails, and leaves the previous contacts in place.
    @discardableResult
    public func addContact(
        contactLabel: String,
        theirPublicB58: String,
        mySecretB58: String,
        myPublicB58: String,
        ratchetCapable: Bool = false
    ) throws -> DmContact {
        ensureLoaded()
        guard loaded else {
            throw KeychainWriteError.status(errSecInteractionNotAllowed)
        }
        let cleanLabel = contactLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanLabel.isEmpty, !cleanLabel.hasPrefix("#") else {
            throw KeychainWriteError.status(errSecParam)
        }
        let contact = DmContact(
            contactLabel: cleanLabel,
            theirPublicB58: theirPublicB58,
            mySecretB58: mySecretB58,
            myPublicB58: myPublicB58,
            ratchetCapable: ratchetCapable
        )
        let previousContacts = contacts
        let previousConversations = conversations
        let replaced = contacts.first { $0.contactLabel.caseInsensitiveCompare(cleanLabel) == .orderedSame }
        let removedIds = Set(
            contacts.filter { $0.contactLabel.caseInsensitiveCompare(cleanLabel) == .orderedSame }.map(\.id)
        )
        contacts.removeAll { removedIds.contains($0.id) }
        conversations.removeAll { removedIds.contains($0.id) }
        contacts.append(contact)

        // Auto-create conversation entry
        let convo = DmConversation(id: contact.id, contactLabel: contact.contactLabel)
        conversations.append(convo)

        guard registerInRust(contact) else {
            contacts = previousContacts
            conversations = previousConversations
            throw KeychainWriteError.status(errSecParam)
        }
        let status = saveContactsToKeychainStatus()
        guard status == errSecSuccess else {
            contacts = previousContacts
            conversations = previousConversations
            if let replaced {
                _ = registerInRust(replaced)
            } else {
                unregisterDmContact(nick: contact.contactLabel)
            }
            throw KeychainWriteError.status(status)
        }
        saveConversationsToDisk()
        let existing = NighthawkContactStore.findByNick(contact.contactLabel)
        NighthawkContactStore.upsert(
            NighthawkContact(
                id: contact.contactLabel.lowercased(),
                nickname: contact.contactLabel,
                dmPublicKey: theirPublicB58,
                walletAddress: existing?.walletAddress,
                ratchetCapable: contact.ratchetCapable
            )
        )
        return contact
    }

    /// Remove a contact by ID.
    public func removeContact(id: String) {
        ensureLoaded()
        guard loaded else { return }
        let previousContacts = contacts
        let previousConversations = conversations
        let removed = contacts.first { $0.id == id }
        contacts.removeAll { $0.id == id }
        conversations.removeAll { $0.id == id }
        guard saveContactsToKeychain() else {
            contacts = previousContacts
            conversations = previousConversations
            return
        }
        saveConversationsToDisk()
        if let removed {
            unregisterDmContact(nick: removed.contactLabel)
            NighthawkContactStore.remove(nick: removed.contactLabel)
        }
    }

    /// Remove contacts matching label (case-insensitive).
    public func removeContact(byLabel label: String) {
        ensureLoaded()
        guard loaded else { return }
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let removed = contacts.filter { $0.contactLabel.lowercased() == normalized }
        guard !removed.isEmpty else { return }
        let previousContacts = contacts
        let previousConversations = conversations
        let removedIds = Set(removed.map(\.id))
        contacts.removeAll { removedIds.contains($0.id) }
        conversations.removeAll { removedIds.contains($0.id) }
        guard saveContactsToKeychain() else {
            contacts = previousContacts
            conversations = previousConversations
            return
        }
        saveConversationsToDisk()
        for item in removed {
            unregisterDmContact(nick: item.contactLabel)
            NighthawkContactStore.remove(nick: item.contactLabel)
        }
    }

    /// Wipe all DM contacts, secrets, and conversations (e.g. on wallet delete).
    public func clearAll() {
        contacts = []
        conversations = []
        loaded = true
        deleteKeychainItem()
        scrubLegacySecretFiles()
        let dir = storageDirectory()
        ChatEncryptedFileStore.remove(
            encryptedURL: dir.appendingPathComponent("dm_conversations.enc"),
            legacyPlaintextURL: dir.appendingPathComponent("dm_conversations.json")
        )
        ChatEncryptedFileStore.clearKey()
        clearDmContacts()
    }

    /// Find a contact by their public key.
    public func findContact(byTheirPublic publicB58: String) -> DmContact? {
        ensureLoaded()
        return contacts.first { $0.theirPublicB58 == publicB58 }
    }

    /// Find a contact by label.
    public func findContact(byLabel label: String) -> DmContact? {
        ensureLoaded()
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return contacts.first { $0.contactLabel.lowercased() == normalized }
    }

    // MARK: - Conversation state

    /// All conversations.
    public func allConversations() -> [DmConversation] {
        ensureLoaded()
        return conversations
    }

    /// Update conversation metadata when a new message arrives.
    public func updateConversation(contactId: String, lastMessage: String, at date: Date = Date(), incrementUnread: Bool = true) {
        ensureLoaded()
        if let idx = conversations.firstIndex(where: { $0.id == contactId }) {
            conversations[idx].lastMessageText = lastMessage
            conversations[idx].lastMessageAt = date
            if incrementUnread {
                conversations[idx].unreadCount += 1
            }
        }
        saveConversationsToDisk()
    }

    /// Clear unread count for a conversation.
    public func clearUnread(contactId: String) {
        ensureLoaded()
        if let idx = conversations.firstIndex(where: { $0.id == contactId }) {
            conversations[idx].unreadCount = 0
        }
        saveConversationsToDisk()
    }
}

// MARK: - Persistence & Migration
private extension DarkircCryptoStore {
    func registerInRust(_ contact: DmContact) -> Bool {
        guard !contact.contactLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let secretBytes = Base58.decode(contact.mySecretB58), secretBytes.count == 32,
              let publicBytes = Base58.decode(contact.theirPublicB58), publicBytes.count == 32 else {
            return false
        }
        do {
            try registerDmContactEx(
                nick: contact.contactLabel,
                mySecret: secretBytes,
                theirPublic: publicBytes,
                ratchetCapable: contact.ratchetCapable
            )
        } catch {
            return false
        }
        return true
    }

    func ensureLoaded() {
        guard !loaded else { return }

        let (keychainData, status) = readFromKeychainWithStatus()
        if status == errSecItemNotAllowed || status == errSecInteractionNotAllowed {
            return
        }
        if status == errSecItemNotFound {
            loaded = true
        } else if status == errSecSuccess,
                  let data = keychainData,
                  let decoded = try? decoder.decode([DmContact].self, from: data) {
            contacts = decoded
            loaded = true
        } else {
            return
        }

        // Migrate any legacy plaintext disk files into Keychain, then securely overwrite & delete.
        let migratedFromDisk = migrateLegacyDiskSecrets()
        if migratedFromDisk {
            if saveContactsToKeychain() {
                scrubLegacySecretFiles()
            }
        } else {
            scrubLegacySecretFiles()
        }

        let dir = storageDirectory()
        let convosEnc = dir.appendingPathComponent("dm_conversations.enc")
        let convosLegacy = dir.appendingPathComponent("dm_conversations.json")
        if let data = ChatEncryptedFileStore.load(
            encryptedURL: convosEnc,
            legacyPlaintextURL: convosLegacy
        ) {
            conversations = (try? decoder.decode([DmConversation].self, from: data)) ?? []
        }
    }

    func migrateLegacyDiskSecrets() -> Bool {
        var didMigrate = false
        for file in legacySecretFileURLs() {
            guard FileManager.default.fileExists(atPath: file.path),
                  let data = try? Data(contentsOf: file) else {
                continue
            }
            if file.lastPathComponent == "dm_contacts.json",
               let diskContacts = try? decoder.decode([DmContact].self, from: data) {
                for item in diskContacts where !contacts.contains(where: {
                    $0.id == item.id || $0.contactLabel.caseInsensitiveCompare(item.contactLabel) == .orderedSame
                }) {
                    contacts.append(item)
                    didMigrate = true
                }
            } else if file.lastPathComponent == "darkirc_crypto_bundle.json",
                      let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let rawContacts = parsed["contacts"] as? [[String: Any]] {
                for entry in rawContacts {
                    guard let nick = (entry["nick"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !nick.isEmpty,
                          let secretB58 = (entry["myDmChachaSecretBase58"] as? String)
                            ?? (entry["my_dm_chacha_secret_base58"] as? String),
                          let publicB58 = (entry["dmChachaPublicBase58"] as? String)
                            ?? (entry["dm_chacha_public_base58"] as? String) else {
                        continue
                    }
                    if !contacts.contains(where: {
                        $0.contactLabel.caseInsensitiveCompare(nick) == .orderedSame
                    }) {
                        contacts.append(
                            DmContact(
                                contactLabel: nick,
                                theirPublicB58: publicB58,
                                mySecretB58: secretB58,
                                myPublicB58: ""
                            )
                        )
                        didMigrate = true
                    }
                }
            }
        }
        return didMigrate
    }

    func legacySecretFileURLs() -> [URL] {
        let appSupportDir = storageDirectory()
        let datastoreDir = daemonDatastoreDirectory()
        return [
            appSupportDir.appendingPathComponent("dm_contacts.json"),
            appSupportDir.appendingPathComponent("darkirc_crypto_bundle.json"),
            datastoreDir.appendingPathComponent("dm_contacts.json"),
            datastoreDir.appendingPathComponent("darkirc_crypto_bundle.json")
        ]
    }

    func scrubLegacySecretFiles() {
        for url in legacySecretFileURLs() {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int, size > 0 {
                let zeros = Data(repeating: 0, count: size)
                try? zeros.write(to: url, options: .atomic)
            }
            try? FileManager.default.removeItem(at: url)
        }
    }

    @discardableResult
    func saveContactsToKeychain() -> Bool { saveContactsToKeychainStatus() == errSecSuccess }

    func saveContactsToKeychainStatus() -> OSStatus {
        guard loaded else { return errSecInteractionNotAllowed }
        guard let data = try? encoder.encode(contacts) else { return errSecParam }
        let status = KeychainGenericPassword.upsert(service: keychainService, account: keychainAccount, data: data)
        if status == errSecSuccess { scrubLegacySecretFiles() }
        return status
    }

    func readFromKeychainWithStatus() -> (Data?, OSStatus) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return (status == errSecSuccess ? item as? Data : nil, status)
    }

    func deleteKeychainItem() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    func saveConversationsToDisk() {
        let dir = storageDirectory()
        let convosEnc = dir.appendingPathComponent("dm_conversations.enc")
        let convosLegacy = dir.appendingPathComponent("dm_conversations.json")
        if let data = try? encoder.encode(conversations) {
            ChatEncryptedFileStore.saveAsync(
                data,
                encryptedURL: convosEnc,
                legacyPlaintextURL: convosLegacy
            )
        }
    }

    func storageDirectory() -> URL {
        if let customStorageDir {
            try? FileManager.default.createDirectory(at: customStorageDir, withIntermediateDirectories: true)
            return customStorageDir
        }
        // swiftlint:disable:next force_unwrapping
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("darkirc", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableDir = dir
        try? mutableDir.setResourceValues(resourceValues)
        return dir
    }

    func daemonDatastoreDirectory() -> URL {
        if let customDatastoreDir {
            return customDatastoreDir
        }
        return URL(fileURLWithPath: DarkircDaemonManager.shared.datastorePath, isDirectory: true)
    }
}
