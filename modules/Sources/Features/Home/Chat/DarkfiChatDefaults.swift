//
//  DarkfiChatDefaults.swift
//  stealth
//
//  Default configuration for DarkFi IRC chat.
//  Matches upstream darkirc autojoin channels and provides
//  persistent hawkXXX nickname generation.
//

import Foundation

/// Default chat configuration matching upstream darkirc.
public enum DarkfiChatDefaults {
    // MARK: - Channels

    /// Default public channels to join — matches upstream darkirc `autojoin`
    /// and Android `DarkfiChatDefaults.DEFAULT_PUBLIC_CHANNELS`.
    public static let defaultPublicChannels: [String] = [
        "#dev",
        "#media",
        "#hackers",
        "#memes",
        "#philosophy",
        "#markets",
        "#math",
        "#random",
        "#lunardao"
    ]

    /// Topic descriptions for default channels (upstream `[channel."#…"]` blocks),
    /// plus a Nighthawk-only fill for `#hackers` (autojoin upstream, no topic block).
    public static let defaultChannelTopics: [String: String] = [
        "#dev": "DarkFi Development HQ",
        "#media": "DarkFi Art, Fashion, Video, Memetics",
        // Nighthawk fill — not present in upstream darkirc_config.toml.
        "#hackers": "Hacker Culture",
        "#memes": "DarkFi Meme Reality",
        "#philosophy": "Philosophy Discussions",
        "#markets": "Crypto Market Talk",
        "#math": "Math Talk",
        "#random": "/b/",
        "#lunardao": "LunarDAO talk"
    ]

    // MARK: - Nickname Limits

    /// Maximum nickname length in characters — must match upstream darkirc.
    public static let maxNickLen = 24

    // MARK: - Persistent Nickname

    private static let nicknameKey = "darkfi_chat_nickname"

    /// Returns a persistent `hawkXXX` nickname.
    ///
    /// On first call, generates a random nickname in the format `hawk000`–`hawk999`
    /// and stores it in UserDefaults. Subsequent calls return the same nickname.
    /// The nickname is non-sensitive app preference data.
    ///
    /// Example nicknames: `hawk042`, `hawk731`, `hawk003`
    public static func persistentNickname() -> String {
        if let stored = UserDefaults.standard.string(forKey: nicknameKey), !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return stored
        }

        let number = Int.random(in: 0...999)
        let nickname = String(format: "hawk%03d", number)
        UserDefaults.standard.set(nickname, forKey: nicknameKey)
        return nickname
    }

    /// Sanitize a nickname to only contain safe characters: `[a-zA-Z0-9_]`.
    /// Matches Android `DarkfiChatPreferences.sanitizeNickname()` for cross-platform
    /// consistency. Falls back to a random `hawkXXX` if the sanitized result is empty.
    public static func sanitizeNickname(_ raw: String) -> String {
        let cleaned = String(raw.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "_"
        }.prefix(maxNickLen))
        if cleaned.isEmpty {
            return String(format: "hawk%03d", Int.random(in: 0...999))
        }
        // Ensure byte length also respects the limit (emoji can be multi-byte).
        var result = cleaned
        while result.utf8.count > maxNickLen {
            result = String(result.dropLast())
        }
        return result
    }

    /// Validate that a nickname string is acceptable for use.
    public static func isValidNickname(_ nickname: String) -> Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxNickLen, trimmed.utf8.count <= maxNickLen else {
            return false
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Set a custom nickname and persist it.
    /// The nickname is sanitized before storage to prevent IRC injection.
    public static func setNickname(_ nickname: String) {
        let sanitized = sanitizeNickname(nickname)
        UserDefaults.standard.set(sanitized, forKey: nicknameKey)
    }

    /// Reset the nickname (for testing or user-requested change).
    /// Next call to `persistentNickname()` will generate a new one.
    public static func resetNickname() {
        UserDefaults.standard.removeObject(forKey: nicknameKey)
    }

    // MARK: - IRC Defaults

    /// Default darkirc IRC server address (loopback when using embedded daemon).
    public static let defaultIrcHost = "127.0.0.1"

    /// Default darkirc IRC server port.
    public static let defaultIrcPort: UInt16 = 6667

    /// Default darkirc datastore directory name inside app support.
    public static let datastoreDirectoryName = "darkirc_db"
}
