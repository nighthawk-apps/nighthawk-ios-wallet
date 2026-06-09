//
//  DarkircDmPubkeyParser.swift
//  stealth
//
//  Parses and generates DarkIRC DM public key exchange strings.
//  Port of Android's DarkircDmPubkeyParser.
//
//  Format: `!darkfi-dm-pubkey:<base58-encoded-public-key>`
//
//  The parser extracts the base58 public key from any text containing this
//  marker (e.g. clipboard paste, QR scan, chat message).
//

import Foundation

public enum DarkircDmPubkeyParser {
    /// The magic prefix used for DM public key exchange.
    public static let prefix = "!darkfi-dm-pubkey:"
    
    /// Extract a base58 DM public key from text containing the marker.
    /// Returns nil if no valid marker found.
    public static func extractFromText(_ text: String) -> String? {
        guard let range = text.range(of: prefix) else { return nil }
        let afterPrefix = text[range.upperBound...]
        
        // Extract the base58 key (alphanumeric chars until whitespace or end)
        let key = afterPrefix.prefix(while: { $0.isLetter || $0.isNumber })
        guard key.count >= 32 else { return nil } // Min reasonable base58 key length
        
        return String(key)
    }
    
    /// Format a public key for sharing.
    /// Returns the full `!darkfi-dm-pubkey:<key>` string.
    public static func formatForSharing(_ publicKeyB58: String) -> String {
        "\(prefix)\(publicKeyB58)"
    }
    
    /// Check if a text contains a DM public key marker.
    public static func containsPubkey(_ text: String) -> Bool {
        text.contains(prefix)
    }
}
