import Foundation
import SwiftUI
import UIComponents

public enum OutboundPeerState: String, Equatable, Sendable {
    case connected
    case connecting
    case sleeping
}

public struct OutboundPeerSlot: Equatable, Identifiable, Sendable {
    public var id: Int { slot }
    public let slot: Int
    public let url: String?
    public let state: OutboundPeerState

    public var displayUrl: String {
        if let url, !url.isEmpty { return url }
        return state.rawValue
    }

    public func dnsName(reverseLookup: (String) -> String? = { _ in nil }) -> String {
        PeerHostDisplay.dnsName(url: url, placeholder: state.rawValue, reverseLookup: reverseLookup)
    }
}

/// Host / DNS name shown in the Chat Network HUD peers dialog.
enum PeerHostDisplay {
    /// Shown instead of an IP literal. Reverse DNS is never performed.
    static let opaquePeerLabel = "peer"

    static func hostFromUrl(_ url: String?) -> String? {
        guard let url, !url.isEmpty else { return nil }
        guard let schemeRange = url.range(of: "://") else { return nil }
        let afterScheme = String(url[schemeRange.upperBound...])
        let hostPort = afterScheme.split(separator: "/").first.map(String.init) ?? afterScheme
        let noQuery = hostPort.split(separator: "?").first.map(String.init) ?? hostPort
        if noQuery.hasPrefix("[") {
            guard let end = noQuery.firstIndex(of: "]") else { return nil }
            let inner = noQuery[noQuery.index(after: noQuery.startIndex)..<end]
            return inner.isEmpty ? nil : String(inner)
        }
        let host = noQuery.split(separator: ":").first.map(String.init) ?? ""
        return host.isEmpty ? nil : host
    }

    static func isOnion(_ host: String) -> Bool {
        host.lowercased().hasSuffix(".onion")
    }

    static func isIpLiteral(_ host: String) -> Bool {
        if host.range(of: #"^\d{1,3}(\.\d{1,3}){3}$"#, options: .regularExpression) != nil {
            return true
        }
        guard host.contains(":") else { return false }
        return host.unicodeScalars.allSatisfy { scalar in
            CharacterSet(charactersIn: "0123456789abcdefABCDEF:.").contains(scalar)
        }
    }

    /// `reverseLookup` is accepted only so tests can `XCTFail` if it is invoked.
    /// IP literals never go through DNS and are never rendered.
    static func dnsName(
        url: String?,
        placeholder: String,
        reverseLookup: (String) -> String? = { _ in nil }
    ) -> String {
        guard let host = hostFromUrl(url) else { return placeholder }
        if isOnion(host) { return host }
        if isIpLiteral(host) { return opaquePeerLabel }
        _ = reverseLookup
        return host
    }
}

public enum OutboundPeerSlots {
    static let hudSlotCount = 3
    static let fileName = "outbound_slots.json"

    static func synthesize(phase: String, daemonRunning: Bool) -> [OutboundPeerSlot] {
        let connecting = daemonRunning && [
            "starting", "waiting_for_peers", "static_sync", "syncing_dag", "loading_history"
        ].contains(phase)
        let connected = daemonRunning && (phase == "connected" || phase == "running")
        return (0..<hudSlotCount).map { index in
            let state: OutboundPeerState
            if connected && index == 0 {
                state = .connected
            } else if connecting {
                state = .connecting
            } else {
                state = .sleeping
            }
            return OutboundPeerSlot(slot: index, url: nil, state: state)
        }
    }

    static func parseJSON(_ raw: String) -> [OutboundPeerSlot] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "[]" else { return [] }
        guard let regex = try? NSRegularExpression(pattern: #"\{[^{}]+\}"#) else { return [] }
        let ns = trimmed as NSString
        let matches = regex.matches(in: trimmed, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { match -> OutboundPeerSlot? in
            let obj = ns.substring(with: match.range)
            guard let slot = firstInt(in: obj, key: "slot") else { return nil }
            let url = firstString(in: obj, key: "url")
            let state = OutboundPeerState(rawValue: firstString(in: obj, key: "state") ?? "sleeping") ?? .sleeping
            return OutboundPeerSlot(slot: slot, url: url, state: state)
        }
        .sorted { $0.slot < $1.slot }
    }

    static func resolve(fileJSON: String?, phase: String, daemonRunning: Bool) -> [OutboundPeerSlot] {
        let parsed = fileJSON.map(parseJSON) ?? []
        if parsed.count == hudSlotCount {
            return parsed
        }
        return synthesize(phase: phase, daemonRunning: daemonRunning)
    }

    static func readSidecar(datastorePath: String) -> String? {
        let url = URL(fileURLWithPath: datastorePath).appendingPathComponent(fileName)
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func firstInt(in obj: String, key: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: "\"\(key)\"\\s*:\\s*(\\d+)") else { return nil }
        let ns = obj as NSString
        guard let match = regex.firstMatch(in: obj, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges > 1 else { return nil }
        return Int(ns.substring(with: match.range(at: 1)))
    }

    private static func firstString(in obj: String, key: String) -> String? {
        if obj.range(of: "\"\(key)\"\\s*:\\s*null", options: .regularExpression) != nil {
            return nil
        }
        guard let regex = try? NSRegularExpression(pattern: "\"\(key)\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"") else {
            return nil
        }
        let ns = obj as NSString
        guard let match = regex.firstMatch(in: obj, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges > 1 else { return nil }
        return ns.substring(with: match.range(at: 1))
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}

enum ChatTimelineItem: Equatable, Identifiable {
    case dateSeparator(epochDay: Int, label: String)
    case message(Chat.State.Message)

    var id: String {
        switch self {
        case let .dateSeparator(day, _): return "day-\(day)"
        case let .message(msg): return msg.id
        }
    }
}

enum ChatTimeline {
    private static let labelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func group(_ messages: [Chat.State.Message], calendar: Calendar = .current) -> [ChatTimelineItem] {
        var items: [ChatTimelineItem] = []
        var lastDay: Date?
        for message in messages {
            let day = calendar.startOfDay(for: message.timestamp)
            if lastDay != day {
                let epochDay = Int(day.timeIntervalSince1970 / 86_400)
                items.append(.dateSeparator(epochDay: epochDay, label: labelFormatter.string(from: day)))
                lastDay = day
            }
            items.append(.message(message))
        }
        return items
    }

    static func gutterTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

/// DarkFi-style hashed nicks + URL chroma, recast in Nighthawk Stealth tokens.
/// Own nick is always accent; peers hash into a cool slate palette (no cyan `#00F0FF`).
/// Incoming/outgoing body is the same two-tone for public group chat and encrypted DMs.
enum ChatChrome {
    static let ownNick = CyberpunkPalette.primary
    static let link = CyberpunkPalette.primary
    static let fud = CyberpunkPalette.reference
    static let bodyIncoming = CyberpunkPalette.muted
    static let bodyOutgoing = CyberpunkPalette.body
    static let timestamp = CyberpunkPalette.muted.opacity(0.7)
    static let bubbleIncoming = CyberpunkPalette.surface
    static let bubbleOutgoing = CyberpunkPalette.surfaceVariant

    static let peerNicks: [Color] = [
        CyberpunkPalette.primary,
        CyberpunkPalette.reference,
        CyberpunkPalette.chipLabel,
        CyberpunkPalette.body,
        CyberpunkPalette.muted,
        CyberpunkPalette.navigationIcon,
        CyberpunkPalette.primary.opacity(0.75),
        CyberpunkPalette.reference.opacity(0.75)
    ]

    static func isOwnNick(_ nick: String, myNick: String) -> Bool {
        guard !nick.isEmpty, !myNick.isEmpty else { return false }
        return nick.caseInsensitiveCompare(myNick) == .orderedSame
    }

    static func peerNickIndex(_ nick: String) -> Int {
        var hash = 0
        for unit in nick.lowercased().utf16 {
            hash = (hash &* 31 &+ Int(unit)) & 0x7FFF_FFFF
        }
        return hash % peerNicks.count
    }

    static func peerNickColor(_ nick: String) -> Color {
        peerNicks[peerNickIndex(nick)]
    }

    static func nickColor(nick: String, myNick: String) -> Color {
        if nick.caseInsensitiveCompare("System") == .orderedSame {
            return timestamp
        }
        return isOwnNick(nick, myNick: myNick) ? ownNick : peerNickColor(nick)
    }

    static func bodyColor(isOwn: Bool) -> Color {
        isOwn ? bodyOutgoing : bodyIncoming
    }

    static func bubbleColor(isOwn: Bool) -> Color {
        isOwn ? bubbleOutgoing : bubbleIncoming
    }

    static func threadIsEncrypted(
        isDirectInbox: Bool,
        threadKey: String,
        encryptedChannelNames: Set<String>
    ) -> Bool {
        if isDirectInbox { return true }
        let key = threadKey.lowercased()
        guard !key.isEmpty else { return false }
        return encryptedChannelNames.contains { $0.lowercased() == key }
    }
}

enum EncryptedChannelIndex {
    static func names(from json: String?) -> Set<String> {
        guard let json, let data = json.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        return Set(
            arr.compactMap { ($0["name"] as? String)?.lowercased() }
                .filter { !$0.isEmpty }
        )
    }
}

struct EncryptedChannelRecord: Equatable, Identifiable, Codable {
    var id: String
    var name: String
    var sharedSecret: String
    var topic: String
}

enum EncryptedChannelStore {
    static func load(json: String?) -> [EncryptedChannelRecord] {
        guard let json, let data = json.data(using: .utf8),
              let rows = try? JSONDecoder().decode([EncryptedChannelRecord].self, from: data)
        else { return [] }
        return rows
    }

    static func upsert(name: String, secret: String, json: String?) -> String? {
        var rows = load(json: json)
        let key = name.lowercased()
        rows.removeAll { $0.name.lowercased() == key }
        rows.append(
            EncryptedChannelRecord(
                id: UUID().uuidString,
                name: name,
                sharedSecret: secret,
                topic: ""
            )
        )
        guard let data = try? JSONEncoder().encode(rows) else { return json }
        return String(data: data, encoding: .utf8)
    }
}

enum ChatInlineSpan: Equatable {
    case text(String)
    case url(String)
    case fud(String)
    case invoice(String)
}

enum ChatMessageLexer {
    private static let pattern = try! NSRegularExpression(
        pattern: #"(fud://[^\s]+)|(https?://[^\s<>"]+)|(drk:[^\s<>"]+)"#,
        options: [.caseInsensitive]
    )

    static func lex(_ text: String) -> [ChatInlineSpan] {
        guard !text.isEmpty else { return [] }
        let ns = text as NSString
        let matches = pattern.matches(in: text, range: NSRange(location: 0, length: ns.length))
        var spans: [ChatInlineSpan] = []
        var cursor = 0
        for match in matches {
            if match.range.location > cursor {
                spans.append(.text(ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))))
            }
            if match.range(at: 1).location != NSNotFound {
                spans.append(.fud(trimPunctuation(ns.substring(with: match.range(at: 1)))))
            } else if match.range(at: 2).location != NSNotFound {
                spans.append(.url(trimPunctuation(ns.substring(with: match.range(at: 2)))))
            } else if match.range(at: 3).location != NSNotFound {
                spans.append(.invoice(trimPunctuation(ns.substring(with: match.range(at: 3)))))
            }
            cursor = match.range.location + match.range.length
        }
        if cursor < ns.length {
            spans.append(.text(ns.substring(from: cursor)))
        }
        return spans
    }

    static func hasFud(_ text: String) -> Bool {
        lex(text).contains { if case .fud = $0 { return true }; return false }
    }

    static func fudUris(_ text: String) -> [String] {
        lex(text).compactMap { span in
            if case let .fud(uri) = span { return uri }
            return nil
        }
    }

    static func invoiceUris(_ text: String) -> [String] {
        lex(text).compactMap { span in
            if case let .invoice(uri) = span { return uri }
            return nil
        }
    }

    private static func trimPunctuation(_ value: String) -> String {
        value.trimmingCharacters(in: CharacterSet(charactersIn: ".,;)"))
    }
}
