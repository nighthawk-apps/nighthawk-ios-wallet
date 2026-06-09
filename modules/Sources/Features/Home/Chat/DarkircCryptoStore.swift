//
//  DarkircCryptoStore.swift
//  stealth
//
//  Persists DM contact crypto configs (ChaCha20 keypairs) in the app sandbox.
//  Port of Android's DmConversationStore + DarkircCryptoManager pattern.
//
//  Each DM contact entry stores:
//    - contactLabel: user-friendly name ("alice")
//    - theirPublicB58: peer's DM public key (base58)
//    - mySecretB58: our generated DM secret key (base58)
//    - myPublicB58: our generated DM public key (base58)
//    - createdAt: ISO-8601 timestamp
//
//  Contacts are stored as a JSON array in `dm_contacts.json` inside the darkirc config directory.
//

import Foundation

// MARK: - DmContact model

/// A DM contact with ChaCha20 keypair crypto configuration.
public struct DmContact: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let contactLabel: String
    public let theirPublicB58: String
    public let mySecretB58: String
    public let myPublicB58: String
    public let createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        contactLabel: String,
        theirPublicB58: String,
        mySecretB58: String,
        myPublicB58: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.contactLabel = contactLabel
        self.theirPublicB58 = theirPublicB58
        self.mySecretB58 = mySecretB58
        self.myPublicB58 = myPublicB58
        self.createdAt = createdAt
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

/// Manages persistence of DM contacts and conversation metadata.
/// Thread-safe via actor isolation.
public actor DarkircCryptoStore {
    public static let shared = DarkircCryptoStore()
    
    private var contacts: [DmContact] = []
    private var conversations: [DmConversation] = []
    
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
    
    private init() {
        Task { await loadFromDisk() }
    }
    
    // MARK: - Contact CRUD
    
    /// All DM contacts.
    public func allContacts() -> [DmContact] { contacts }
    
    /// Add a new DM contact. Returns the saved contact.
    @discardableResult
    public func addContact(
        contactLabel: String,
        theirPublicB58: String,
        mySecretB58: String,
        myPublicB58: String
    ) -> DmContact {
        let contact = DmContact(
            contactLabel: contactLabel.trimmingCharacters(in: .whitespacesAndNewlines),
            theirPublicB58: theirPublicB58,
            mySecretB58: mySecretB58,
            myPublicB58: myPublicB58
        )
        contacts.append(contact)
        
        // Auto-create conversation entry
        let convo = DmConversation(id: contact.id, contactLabel: contact.contactLabel)
        conversations.append(convo)
        
        saveToDisk()
        return contact
    }
    
    /// Remove a contact by ID.
    public func removeContact(id: String) {
        contacts.removeAll { $0.id == id }
        conversations.removeAll { $0.id == id }
        saveToDisk()
    }
    
    /// Find a contact by their public key.
    public func findContact(byTheirPublic publicB58: String) -> DmContact? {
        contacts.first { $0.theirPublicB58 == publicB58 }
    }
    
    /// Find a contact by label.
    public func findContact(byLabel label: String) -> DmContact? {
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return contacts.first { $0.contactLabel.lowercased() == normalized }
    }
    
    // MARK: - Conversation state
    
    /// All conversations.
    public func allConversations() -> [DmConversation] { conversations }
    
    /// Update conversation metadata when a new message arrives.
    public func updateConversation(contactId: String, lastMessage: String, at date: Date = Date(), incrementUnread: Bool = true) {
        if let idx = conversations.firstIndex(where: { $0.id == contactId }) {
            conversations[idx].lastMessageText = lastMessage
            conversations[idx].lastMessageAt = date
            if incrementUnread {
                conversations[idx].unreadCount += 1
            }
        }
        saveToDisk()
    }
    
    /// Clear unread count for a conversation.
    public func clearUnread(contactId: String) {
        if let idx = conversations.firstIndex(where: { $0.id == contactId }) {
            conversations[idx].unreadCount = 0
        }
        saveToDisk()
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        let dir = storageDirectory()
        
        // Load contacts
        let contactsFile = dir.appendingPathComponent("dm_contacts.json")
        if let data = try? Data(contentsOf: contactsFile) {
            contacts = (try? decoder.decode([DmContact].self, from: data)) ?? []
        }
        
        // Load conversations
        let convosFile = dir.appendingPathComponent("dm_conversations.json")
        if let data = try? Data(contentsOf: convosFile) {
            conversations = (try? decoder.decode([DmConversation].self, from: data)) ?? []
        }
    }
    
    private func saveToDisk() {
        let dir = storageDirectory()
        
        // Save contacts
        if let data = try? encoder.encode(contacts) {
            try? data.write(to: dir.appendingPathComponent("dm_contacts.json"), options: .atomic)
        }
        
        // Save conversations
        if let data = try? encoder.encode(conversations) {
            try? data.write(to: dir.appendingPathComponent("dm_conversations.json"), options: .atomic)
        }
    }
    
    private func storageDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("darkirc", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
