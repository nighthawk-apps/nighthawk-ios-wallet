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
    
    /// Default public channels to join — matches upstream darkirc `autojoin` config.
    public static let defaultPublicChannels: [String] = [
        "#dev",
        "#random",
        "#lunardao"
    ]
    
    /// Topic descriptions for default channels.
    public static let defaultChannelTopics: [String: String] = [
        "#dev": "DarkFi development",
        "#random": "Off-topic discussion",
        "#lunardao": "LunarDAO community"
    ]
    
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
        if let stored = UserDefaults.standard.string(forKey: nicknameKey),
           stored.hasPrefix("hawk") && stored.count == 7 {
            return stored
        }
        
        let number = Int.random(in: 0...999)
        let nickname = String(format: "hawk%03d", number)
        UserDefaults.standard.set(nickname, forKey: nicknameKey)
        return nickname
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
