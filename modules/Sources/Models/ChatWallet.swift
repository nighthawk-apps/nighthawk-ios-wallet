import Foundation
import CryptoKit

/// Delivery of an outgoing chat line (parity with Android ChatDeliveryState).
public enum ChatDeliveryState: String, Equatable {
    case queued
    case sending
    case relayed
    case failed
}

/// On-chain receipt posted into a chat thread.
public enum ChatReceiptPhase: String, Equatable, Codable {
    case pending
    case broadcasted
    case confirmed
    case failed
}

public struct NighthawkContact: Equatable, Identifiable {
    public var id: String
    public var nickname: String
    public var dmPublicKey: String
    public var walletAddress: String?

    public init(id: String, nickname: String, dmPublicKey: String, walletAddress: String? = nil) {
        self.id = id
        self.nickname = nickname
        self.dmPublicKey = dmPublicKey
        self.walletAddress = walletAddress
    }
}

public enum NighthawkContacts {
    public static func safetyNumber(dmPublicKey: String, walletAddress: String?) -> String {
        let trimmedKey = dmPublicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddr = walletAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let material = "\(trimmedKey)|\(trimmedAddr)"
        let digest = SHA256.hash(data: Data(material.utf8))
        // Match Android `abs(byte.toInt())`: SHA-256 bytes are signed.
        let groups = digest.prefix(15).map { byte in
            let signed = Int(Int8(bitPattern: byte))
            return String(format: "%05d", abs(signed) % 100_000)
        }
        return groups.joined(separator: " ")
    }

    /// Wallet receive identity is a DarkFi address in a `drk:` invoice.
    /// Returns nil when the contact has no DarkFi address. DAO ids are DarkFi bullas, not this URI.
    public static func inviteUri(_ contact: NighthawkContact) -> String? {
        let addr = contact.walletAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !addr.isEmpty else { return nil }
        return "drk:\(addr)"
    }

    /// Full Nighthawk contact invite URI carrying nickname, DM public key, and/or wallet address.
    public static func contactInviteUri(_ contact: NighthawkContact) -> String? {
        let nick = contact.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let dmKey = contact.dmPublicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let addr = contact.walletAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !dmKey.isEmpty || !addr.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "nighthawk"
        components.host = "contact"
        var items: [URLQueryItem] = []
        if !nick.isEmpty { items.append(URLQueryItem(name: "nick", value: nick)) }
        if !dmKey.isEmpty { items.append(URLQueryItem(name: "dm", value: dmKey)) }
        if !addr.isEmpty { items.append(URLQueryItem(name: "addr", value: addr)) }
        components.queryItems = items
        return components.string
    }

    public static func parseInvite(_ raw: String) -> NighthawkContact? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("nighthawk://contact"),
           let components = URLComponents(string: trimmed) {
            let items = components.queryItems ?? []
            func item(_ names: String...) -> String {
                for name in names {
                    if let val = items.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.value?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                       !val.isEmpty {
                        return val
                    }
                }
                return ""
            }
            let nick = item("nick", "name", "label")
            let dmKey = item("dm", "pubkey", "dm_pubkey", "dmPublicKey")
            let addr = item("addr", "address", "wallet", "walletAddress")
            guard !dmKey.isEmpty || !addr.isEmpty else { return nil }
            let id = !nick.isEmpty ? nick.lowercased() : (!addr.isEmpty ? addr : dmKey)
            return NighthawkContact(
                id: id,
                nickname: nick,
                dmPublicKey: dmKey,
                walletAddress: addr.isEmpty ? nil : addr
            )
        }

        guard let parsed = PaymentRequestUri.parse(trimmed),
              trimmed.lowercased().hasPrefix("drk:") || trimmed.lowercased().hasPrefix("darkfi:")
        else { return nil }
        guard !parsed.address.isEmpty else { return nil }
        return NighthawkContact(
            id: parsed.address,
            nickname: "",
            dmPublicKey: "",
            walletAddress: parsed.address
        )
    }
}

public enum ChatLinkGuard {
    public static func isClearnetHttp(_ url: String) -> Bool {
        let lower = url.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower.hasPrefix("http://") || lower.hasPrefix("https://")
    }

    /// First http(s) token in a chat line, without trailing punctuation.
    public static func firstClearnet(in text: String) -> String? {
        for token in text.split(whereSeparator: { $0.isWhitespace || $0 == "\n" }) {
            let raw = String(token).trimmingCharacters(in: CharacterSet(charactersIn: ".,;)]}>\"'"))
            if isClearnetHttp(raw) { return raw }
        }
        return nil
    }
}

public struct ChatReceipt: Equatable, Codable {
    public var id: String
    public var phase: ChatReceiptPhase
    public var amount: String
    public var address: String
    public var memo: String?
    public var txId: String?

    public init(
        id: String,
        phase: ChatReceiptPhase,
        amount: String,
        address: String,
        memo: String? = nil,
        txId: String? = nil
    ) {
        self.id = id
        self.phase = phase
        self.amount = amount
        self.address = address
        self.memo = memo
        self.txId = txId
    }
}

/// Wire form shared with Android: `nh-receipt:v1|phase|id|amount|address|memoB64|-|txid|-`
public enum ChatReceiptCodec {
    public static let prefix = "nh-receipt:v1"

    public static func encode(_ receipt: ChatReceipt) -> String {
        let memo: String
        if let text = receipt.memo?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            memo = Data(text.utf8).base64EncodedString()
        } else {
            memo = "-"
        }
        let tx = receipt.txId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? sanitize(receipt.txId ?? "")
            : "-"
        return [
            prefix,
            receipt.phase.rawValue,
            sanitize(receipt.id),
            sanitize(receipt.amount),
            sanitize(receipt.address),
            memo,
            tx
        ].joined(separator: "|")
    }

    public static func parse(_ text: String) -> ChatReceipt? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("\(prefix)|") else { return nil }
        let parts = trimmed.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 7, let phase = ChatReceiptPhase(rawValue: parts[1].lowercased()) else {
            return nil
        }
        let memo: String?
        if parts[5] == "-" {
            memo = nil
        } else if let data = Data(base64Encoded: parts[5]), let text = String(data: data, encoding: .utf8), !text.isEmpty {
            memo = text
        } else {
            memo = nil
        }
        let tx = parts[6].isEmpty || parts[6] == "-" ? nil : parts[6]
        return ChatReceipt(
            id: parts[2],
            phase: phase,
            amount: parts[3],
            address: parts[4],
            memo: memo,
            txId: tx
        )
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "|", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Live receipt phases. Broadcast is not confirmation.
public enum ChatReceiptBook {
    private static let pendingKey = "nighthawk.pendingChatReceipt"
    private static let pendingTargetKey = "nighthawk.pendingChatReceiptTarget"
    private static let readyKey = "nighthawk.readyChatReceiptId"
    private static let readyTargetKey = "nighthawk.readyChatReceiptTarget"
    private static let mapKey = "nighthawk.chatReceipts.v1"

    public static func stage(_ receipt: ChatReceipt, targetChannel: String? = nil) {
        var all = loadMap()
        all[receipt.id] = receipt
        saveMap(all)
        UserDefaults.standard.set(receipt.id, forKey: pendingKey)
        if let targetChannel = targetChannel?.trimmingCharacters(in: .whitespacesAndNewlines),
           !targetChannel.isEmpty {
            UserDefaults.standard.set(targetChannel, forKey: pendingTargetKey)
        } else {
            UserDefaults.standard.removeObject(forKey: pendingTargetKey)
        }
    }

    public static func lookup(id: String) -> ChatReceipt? {
        loadMap()[id]
    }

    @discardableResult
    public static func markBroadcasted(txId: String) -> (receipt: ChatReceipt, targetChannel: String?)? {
        guard let id = UserDefaults.standard.string(forKey: pendingKey), var receipt = lookup(id: id) else {
            return nil
        }
        receipt.phase = .broadcasted
        receipt.txId = txId
        var all = loadMap()
        all[id] = receipt
        saveMap(all)
        let targetChannel = UserDefaults.standard.string(forKey: pendingTargetKey)
        UserDefaults.standard.removeObject(forKey: pendingKey)
        UserDefaults.standard.removeObject(forKey: pendingTargetKey)
        UserDefaults.standard.set(id, forKey: readyKey)
        if let targetChannel, !targetChannel.isEmpty {
            UserDefaults.standard.set(targetChannel, forKey: readyTargetKey)
        } else {
            UserDefaults.standard.removeObject(forKey: readyTargetKey)
        }
        return (receipt, targetChannel)
    }

    public static func consumeReadyToPost() -> (receipt: ChatReceipt, targetChannel: String?)? {
        guard let id = UserDefaults.standard.string(forKey: readyKey),
              let receipt = lookup(id: id) else {
            return nil
        }
        let targetChannel = UserDefaults.standard.string(forKey: readyTargetKey)
        UserDefaults.standard.removeObject(forKey: readyKey)
        UserDefaults.standard.removeObject(forKey: readyTargetKey)
        return (receipt, targetChannel)
    }

    public static func clearPending() {
        if let id = UserDefaults.standard.string(forKey: pendingKey) {
            var all = loadMap()
            all.removeValue(forKey: id)
            saveMap(all)
        }
        UserDefaults.standard.removeObject(forKey: pendingKey)
        UserDefaults.standard.removeObject(forKey: pendingTargetKey)
    }

    public static func clearAll() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
        UserDefaults.standard.removeObject(forKey: pendingTargetKey)
        UserDefaults.standard.removeObject(forKey: readyKey)
        UserDefaults.standard.removeObject(forKey: readyTargetKey)
        UserDefaults.standard.removeObject(forKey: mapKey)
    }

    private static func loadMap() -> [String: ChatReceipt] {
        guard let data = UserDefaults.standard.data(forKey: mapKey),
              let decoded = try? JSONDecoder().decode([String: ChatReceipt].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func saveMap(_ map: [String: ChatReceipt]) {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: mapKey)
        }
    }
}

public enum ChatNotificationPolicy {
    public static let lockscreenText = "New private message"
    public static let freshSeconds: TimeInterval = 90

    public static func shouldAlert(
        isOutgoing: Bool,
        ownNick: String,
        nick: String,
        timestamp: Date,
        now: Date = Date()
    ) -> Bool {
        if isOutgoing { return false }
        let own = ownNick.trimmingCharacters(in: .whitespacesAndNewlines)
        if !own.isEmpty && nick.compare(own, options: .caseInsensitive) == .orderedSame { return false }
        if nick.compare("System", options: .caseInsensitive) == .orderedSame { return false }
        let age = now.timeIntervalSince(timestamp)
        if age > freshSeconds { return false }
        if timestamp.timeIntervalSince(now) > 5 { return false }
        return true
    }
}

public enum ChatDeliveryLabel {
    public static func from(eventId: String, isOutgoing: Bool) -> ChatDeliveryState? {
        if eventId.hasPrefix("failed-") { return .failed }
        if eventId.hasPrefix("queued-") { return .queued }
        if eventId.hasPrefix("local-") { return .sending }
        if isOutgoing { return .relayed }
        return nil
    }
}
