//
//  DerivationToolLiveKey.swift
//  stealth
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture
import Foundation

extension DerivationToolClient: DependencyKey {
    public static let liveValue = DerivationToolClient.live()

    public static func live() -> Self {
        Self(
            isDarkFiAddress: { address, _ in
                DarkFiAddressValidator.isValid(address)
            }
        )
    }
}

/// Validates bare DarkFi receive addresses (not `drk:` / `darkfi:` URIs).
enum DarkFiAddressValidator {
    private static let base58Alphabet = CharacterSet(charactersIn:
        "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    )

    /// DarkFi `Address` bs58 encodings are typically ~50–70 chars.
    private static let minLength = 40
    private static let maxLength = 128

    static func isValid(_ raw: String) -> Bool {
        let address = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return false }
        // Reject payment URIs / query strings — callers must parse first.
        if address.contains(":") || address.contains("?") || address.contains("/") {
            return false
        }
        guard (minLength...maxLength).contains(address.count) else { return false }
        return address.unicodeScalars.allSatisfy { base58Alphabet.contains($0) }
    }
}
