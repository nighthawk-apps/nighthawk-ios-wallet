//
//  LightwalletTlsPin.swift
//  DarkfiCore
//
//  Resolves SHA-256 of lightwalletd leaf certificate DER for TLS pinning (S8).
//

import Foundation

public enum LightwalletTlsPin {
    public static let userDefaultsKey = "lightwallet_tls_pin_sha256"
    public static let infoPlistKey = "LightwalletTlsPinSha256"

    /// Resolve the lightwalletd leaf-cert SHA-256 pin (32 raw bytes).
    ///
    /// **Production:** `LightwalletTlsPinSha256` in Info.plist only.
    /// **Debug/QA:** `UserDefaults` key `lightwallet_tls_pin_sha256` may override
    /// so local testing can pin a different server without rebuilding.
    ///
    /// Remote HTTPS without any pin remains **fail-closed** in Rust bootstrap (S8/S12).
    public static func pinDataOrNil(
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> Data? {
        #if DEBUG
        if let fromDefaults = parseHexPin(defaults.string(forKey: userDefaultsKey)) {
            return fromDefaults
        }
        #endif
        return parseHexPin(bundle.object(forInfoDictionaryKey: infoPlistKey) as? String)
    }

    public static func parseHexPin(_ hex: String?) -> Data? {
        guard var cleaned = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !cleaned.isEmpty else {
            return nil
        }
        if cleaned.hasPrefix("0x") || cleaned.hasPrefix("0X") {
            cleaned = String(cleaned.dropFirst(2))
        }
        cleaned = cleaned.filter { !$0.isWhitespace && $0 != ":" }.lowercased()
        guard cleaned.count == 64, cleaned.allSatisfy({ $0.isHexDigit }) else {
            return nil
        }
        var data = Data(capacity: 32)
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let next = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<next], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = next
        }
        return data.count == 32 ? data : nil
    }
}
