import Foundation

/// Parsed `fud://<infohash>/<filename>` offer. The file bytes are not fetched here.
public struct FudUri: Equatable {
    public let infoHash: String
    public let fileName: String?
    public let raw: String

    public var displayName: String { fileName ?? infoHash }

    public static func parse(_ raw: String) -> FudUri? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("fud://") else { return nil }
        let rest = String(trimmed.dropFirst(6))
        let slash = rest.firstIndex(of: "/")
        let host = slash.map { String(rest[..<$0]) } ?? rest
        let path = slash.map { String(rest[rest.index(after: $0)...]) } ?? ""
        guard isValidInfoHash(host) else { return nil }
        let name: String?
        if path.isEmpty {
            name = nil
        } else if let sanitized = sanitizeFileName(path) {
            name = sanitized
        } else {
            return nil
        }
        let canonical: String
        if let name {
            canonical = "fud://\(host.lowercased())/\(name)"
        } else {
            canonical = "fud://\(host.lowercased())"
        }
        return FudUri(infoHash: host.lowercased(), fileName: name, raw: canonical)
    }

    /// First `fud://` token in a chat line.
    public static func find(in text: String) -> FudUri? {
        for token in text.split(whereSeparator: { $0.isWhitespace || $0 == "\n" }) {
            if let uri = parse(String(token)) {
                return uri
            }
        }
        return nil
    }

    public static func isValidInfoHash(_ host: String) -> Bool {
        guard (4...128).contains(host.count) else { return false }
        return host.allSatisfy { $0.isLetter || $0.isNumber }
    }

    public static func sanitizeFileName(_ path: String) -> String? {
        if path.contains("/") || path.contains("\\") || path.contains("..") { return nil }
        let name = path.split(separator: "/").last.map(String.init) ?? path
        if name.isEmpty || name == "." || name == ".." || name.count > 255 { return nil }
        return name
    }
}

public enum FudTransferDecision: Equatable {
    case allowed
    case disabled
    case needsPrivateTransport
    case invalid
}

public enum FudTransferPolicy {
    /// Offers proceed over Tor, Nym, or nearby mesh. Clearnet is rejected.
    public static func decide(
        enabled: Bool,
        privateTransport: Bool,
        meshOn: Bool,
        uri: FudUri?
    ) -> FudTransferDecision {
        guard uri != nil else { return .invalid }
        guard enabled else { return .disabled }
        return (privateTransport || meshOn) ? .allowed : .needsPrivateTransport
    }
}

public enum FudPreferences {
    public static let enabledKey = "darkfiAllowFudTransfers"

    public static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    public static func setEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: enabledKey)
    }
}

public enum FudOfferInbox {
    public static func queue(uri: FudUri, now: Date = Date(), directory: URL? = nil) throws -> URL {
        let root = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = root.appendingPathComponent("fud-offers", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(uri.infoHash).json")
        let payload: [String: Any] = [
            "infoHash": uri.infoHash,
            "fileName": uri.fileName.map { $0 as Any } ?? NSNull(),
            "queuedAtEpochMs": Int(now.timeIntervalSince1970 * 1000)
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        try data.write(to: file, options: .atomic)
        return file
    }
}
