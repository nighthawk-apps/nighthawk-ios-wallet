import Foundation

/// Offline chat sends. Flushed when DarkIRC reports connected.
actor ChatOutboxStore {
    static let shared = ChatOutboxStore()

    struct Record: Codable, Equatable {
        var id: String
        var channel: String
        var text: String
        var delivery: String
    }

    private let fileURL: URL
    private var records: [Record] = []
    private var loaded = false

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("nighthawk-chat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("chat_outbox_v1.json")
    }

    func enqueue(channel: String, text: String) -> String {
        ensureLoaded()
        let id = "queued-\(UUID().uuidString)"
        records.append(Record(id: id, channel: channel, text: text, delivery: "queued"))
        if records.count > 200 {
            records.removeFirst(records.count - 200)
        }
        persist()
        return id
    }

    func loadAll() -> [Record] {
        ensureLoaded()
        return records
    }

    func updateDelivery(id: String, delivery: String) {
        ensureLoaded()
        guard let idx = records.firstIndex(where: { $0.id == id }) else { return }
        records[idx].delivery = delivery
        persist()
    }

    func remove(id: String) {
        ensureLoaded()
        records.removeAll { $0.id == id }
        persist()
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
        try? data.write(to: fileURL, options: .atomic)
    }
}
