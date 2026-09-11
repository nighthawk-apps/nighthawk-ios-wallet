import Foundation
import SwiftUI

enum OutboundPeerState: String, Equatable {
    case connected
    case connecting
    case sleeping
}

struct OutboundPeerSlot: Equatable, Identifiable {
    var id: Int { slot }
    let slot: Int
    let url: String?
    let state: OutboundPeerState

    var displayUrl: String {
        if let url, !url.isEmpty { return url }
        return state.rawValue
    }
}

enum OutboundPeerSlots {
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
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
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
    static let ownNick = Color(red: 94 / 255, green: 155 / 255, blue: 175 / 255) // #5E9BAF
    static let link = Color(red: 125 / 255, green: 173 / 255, blue: 185 / 255) // #7DADB9
    static let fud = Color(red: 143 / 255, green: 152 / 255, blue: 163 / 255) // #8F98A3
    static let bodyIncoming = Color(red: 196 / 255, green: 203 / 255, blue: 212 / 255) // #C4CBD4
    static let bodyOutgoing = Color(red: 232 / 255, green: 235 / 255, blue: 239 / 255) // #E8EBEF
    static let timestamp = Color(red: 143 / 255, green: 152 / 255, blue: 163 / 255)
    static let bubbleIncoming = Color(red: 23 / 255, green: 28 / 255, blue: 34 / 255) // #171C22
    static let bubbleOutgoing = Color(red: 36 / 255, green: 48 / 255, blue: 56 / 255) // #243038

    static let peerNicks: [Color] = [
        Color(red: 125 / 255, green: 173 / 255, blue: 185 / 255), // accent muted
        Color(red: 122 / 255, green: 163 / 255, blue: 243 / 255), // bright blue
        Color(red: 155 / 255, green: 189 / 255, blue: 207 / 255), // cool slate
        Color(red: 157 / 255, green: 234 / 255, blue: 121 / 255), // bright green
        Color(red: 168 / 255, green: 178 / 255, blue: 189 / 255), // navigation muted
        Color(red: 156 / 255, green: 87 / 255, blue: 118 / 255), // plum
        Color(red: 79 / 255, green: 135 / 255, blue: 153 / 255), // accent pressed
        Color(red: 197 / 255, green: 206 / 255, blue: 214 / 255) // parmaviolet
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

enum ChatInlineSpan: Equatable {
    case text(String)
    case url(String)
    case fud(String)
}

enum ChatMessageLexer {
    private static let pattern = try! NSRegularExpression(
        pattern: #"(fud://[^\s]+)|(https?://[^\s<>"]+)"#,
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

    private static func trimPunctuation(_ value: String) -> String {
        value.trimmingCharacters(in: CharacterSet(charactersIn: ".,;)"))
    }
}
