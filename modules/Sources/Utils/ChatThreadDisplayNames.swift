import Foundation

public enum ChatThreadDisplayNames {
    private static let key = "nighthawk.chat_thread_display_names"

    public static func load() -> [String: String] {
        (UserDefaults.standard.dictionary(forKey: key) as? [String: String]) ?? [:]
    }

    public static func put(threadKey: String, displayName: String) {
        var map = load()
        let key = threadKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = String(displayName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(32))
        if name.isEmpty {
            map.removeValue(forKey: key)
        } else {
            map[key] = name
        }
        UserDefaults.standard.set(map, forKey: self.key)
    }

    public static func display(_ threadKey: String) -> String {
        let map = load()
        return map[threadKey]?.isEmpty == false ? map[threadKey]! : threadKey
    }
}
