import Foundation

/// Parsed `fud://<infohash>/<filename>` offer. Geode bytes are not fetched here.
public struct FudUri: Equatable, Codable, Sendable {
    public let infoHash: String
    public let fileName: String?
    public let raw: String

    public var displayName: String { fileName ?? infoHash }

    public static func parse(_ raw: String) -> FudUri? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme?.lowercased() == "fud" else {
            return nil
        }
        guard let host = url.host, isValidInfoHash(host) else { return nil }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let name: String?
        if path.isEmpty {
            name = nil
        } else {
            guard let sanitized = sanitizeFileName(path) else { return nil }
            name = sanitized
        }
        let canonical =
            name.map { "fud://\(host.lowercased())/\($0)" } ?? "fud://\(host.lowercased())"
        return FudUri(infoHash: host.lowercased(), fileName: name, raw: canonical)
    }

    static func isValidInfoHash(_ host: String) -> Bool {
        let count = host.count
        guard (4...128).contains(count) else { return false }
        return host.allSatisfy { $0.isLetter || $0.isNumber }
    }

    static func sanitizeFileName(_ path: String) -> String? {
        if path.contains("/") || path.contains("\\") || path.contains("..") {
            return nil
        }
        let name = (path as NSString).lastPathComponent
        guard !name.isEmpty, name != ".", name != "..", name.count <= 255 else { return nil }
        return name
    }
}

public enum ChatFudPrompt: Equatable {
    case confirm(uri: String, fileName: String)
    case disabled
    case needsPrivateTransport
    case invalid
    case queued(fileName: String)
    case queueFailed
}

public enum FudTransferDecision: Equatable {
    case allowed
    case disabled
    case needsPrivateTransport
    case invalid
}

/// File offers only proceed over Tor or mesh. Clearnet is rejected.
public enum FudTransferPolicy {
    public static func decide(
        enabled: Bool,
        torReady: Bool,
        meshOn: Bool,
        uri: FudUri?
    ) -> FudTransferDecision {
        guard uri != nil else { return .invalid }
        guard enabled else { return .disabled }
        if torReady || meshOn { return .allowed }
        return .needsPrivateTransport
    }
}

struct QueuedFudOffer: Equatable, Codable {
    let infoHash: String
    let fileName: String?
    let queuedAt: TimeInterval
}

enum FudOfferInbox {
    static func queue(_ uri: FudUri) throws {
        let dir = try directory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(uri.infoHash).json")
        let offer = QueuedFudOffer(
            infoHash: uri.infoHash,
            fileName: uri.fileName,
            queuedAt: Date().timeIntervalSince1970
        )
        let data = try JSONEncoder().encode(offer)
        try data.write(to: file, options: .atomic)
    }

    static func directory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent("fud-offers", isDirectory: true)
    }
}
