import Foundation

public struct DeviceAddressBookEntry: Equatable, Identifiable, Codable {
    public var id: String { address }
    public var label: String
    public var address: String

    public init(label: String, address: String) {
        self.label = label
        self.address = address
    }
}

/// Device-only labels. No ENS and no network lookup.
public enum DeviceAddressBook {
    private static let key = "nighthawk.device_address_book"

    public static func load() -> [DeviceAddressBookEntry] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([DeviceAddressBookEntry].self, from: data)) ?? []
    }

    public static func upsert(label: String, address: String) {
        let trimmedLabel = String(label.trimmingCharacters(in: .whitespacesAndNewlines).prefix(64))
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty, !trimmedAddress.isEmpty else { return }
        var next = load().filter { $0.address.caseInsensitiveCompare(trimmedAddress) != .orderedSame }
        next.insert(DeviceAddressBookEntry(label: trimmedLabel, address: trimmedAddress), at: 0)
        persist(Array(next.prefix(50)))
    }

    private static func persist(_ entries: [DeviceAddressBookEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
