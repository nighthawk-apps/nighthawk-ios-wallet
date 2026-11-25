import Foundation

/// Capped on-disk chat history (AES-GCM encrypted at rest) so a reconnect does not wipe the thread.
public enum ChatHistoryStore {
    struct Snapshot {
        var channels: [String: [Chat.State.Message]]
        var dms: [String: [Chat.State.Message]]
        var ids: Set<String>
    }

    private struct FileModel: Codable {
        var channels: [String: [Line]]
        var dms: [String: [Line]]
    }

    private struct Line: Codable {
        var id: String
        var sender: String
        var content: String
        var channel: String
        var timestamp: TimeInterval
        var isOutgoing: Bool
        var failedToDecrypt: Bool
    }

    private static var storageDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        var dir = base.appendingPathComponent("nighthawk-chat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
        return dir
    }

    private static var encryptedFileURL: URL {
        storageDir.appendingPathComponent("chat_history_v1.enc")
    }

    private static var legacyPlaintextURL: URL {
        storageDir.appendingPathComponent("chat_history_v1.json")
    }

    static func load() -> Snapshot {
        guard let data = ChatEncryptedFileStore.load(
            encryptedURL: encryptedFileURL,
            legacyPlaintextURL: legacyPlaintextURL
        ),
              let model = try? JSONDecoder().decode(FileModel.self, from: data) else {
            return Snapshot(channels: [:], dms: [:], ids: [])
        }
        let channels = model.channels.mapValues { $0.map(message) }
        let dms = model.dms.mapValues { $0.map(message) }
        var ids = Set<String>()
        for lines in channels.values { ids.formUnion(lines.map(\.id)) }
        for lines in dms.values { ids.formUnion(lines.map(\.id)) }
        return Snapshot(channels: channels, dms: dms, ids: ids)
    }

    static func save(channels: [String: [Chat.State.Message]], dms: [String: [Chat.State.Message]]) {
        let model = FileModel(
            channels: channels.mapValues { Array($0.suffix(200)).map(line) },
            dms: dms.mapValues { Array($0.suffix(200)).map(line) }
        )
        let encURL = encryptedFileURL
        let legacyURL = legacyPlaintextURL
        ChatEncryptedFileStore.diskQueue.async {
            guard let data = try? JSONEncoder().encode(model) else { return }
            ChatEncryptedFileStore.saveAsync(data, encryptedURL: encURL, legacyPlaintextURL: legacyURL)
        }
    }

    public static func clearAll() {
        let dir = storageDir
        ChatEncryptedFileStore.remove(encryptedURL: encryptedFileURL, legacyPlaintextURL: legacyPlaintextURL)
        if let contents = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
           contents.isEmpty {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    private static func line(_ message: Chat.State.Message) -> Line {
        Line(
            id: message.id,
            sender: message.sender,
            content: message.content,
            channel: message.channel,
            timestamp: message.timestamp.timeIntervalSince1970,
            isOutgoing: message.isOutgoing,
            failedToDecrypt: message.failedToDecrypt
        )
    }

    private static func message(_ line: Line) -> Chat.State.Message {
        Chat.State.Message(
            id: line.id,
            sender: line.sender,
            content: line.content,
            channel: line.channel,
            timestamp: Date(timeIntervalSince1970: line.timestamp),
            isOutgoing: line.isOutgoing,
            failedToDecrypt: line.failedToDecrypt
        )
    }
}
