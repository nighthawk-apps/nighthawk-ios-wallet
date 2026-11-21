import Foundation

/// Offline chat sends. Flushed when DarkIRC reports connected.
public actor ChatOutboxStore {
    public static let shared = ChatOutboxStore()

    public struct Record: Codable, Equatable, Sendable {
        public var id: String
        public var channel: String
        public var text: String
        public var delivery: String

        public init(id: String, channel: String, text: String, delivery: String) {
            self.id = id
            self.channel = channel
            self.text = text
            self.delivery = delivery
        }
    }

    private let fileURL: URL
    private var records: [Record] = []
    private var loaded = false

    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            var dir = base.appendingPathComponent("nighthawk-chat", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? dir.setResourceValues(values)
            self.fileURL = dir.appendingPathComponent("chat_outbox_v1.json")
        }
    }

    @discardableResult
    public func enqueue(id: String? = nil, channel: String, text: String) -> String {
        ensureLoaded()
        let recordId = id ?? "queued-\(UUID().uuidString)"
        if !records.contains(where: { $0.id == recordId }) {
            records.append(Record(id: recordId, channel: channel, text: text, delivery: "queued"))
        }
        if records.count > 200 {
            records.removeFirst(records.count - 200)
        }
        persist()
        return recordId
    }

    public func loadAll() -> [Record] {
        ensureLoaded()
        return records
    }

    public func updateDelivery(id: String, delivery: String) {
        ensureLoaded()
        guard let idx = records.firstIndex(where: { $0.id == id }) else { return }
        records[idx].delivery = delivery
        persist()
    }

    public func remove(id: String) {
        ensureLoaded()
        records.removeAll { $0.id == id }
        persist()
    }

    public func clearAll() {
        records = []
        loaded = true
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func ensureLoaded() {
        guard !loaded else { return }
        loaded = true
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Record].self, from: data) else {
            return
        }
        records = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
