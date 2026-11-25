//
//  LightwalletTlsPin.swift
//  DarkfiCore
//
//  Resolves SHA-256 of lightwalletd leaf certificate DER for TLS pinning (S8),
//  with rotation support (`previousPin`) and fail-closed remote HTTPS validation.
//

import Foundation

public enum LightwalletTlsPin {
    public static let userDefaultsKey = "lightwallet_tls_pin_sha256"
    public static let previousUserDefaultsKey = "lightwallet_tls_pin_previous_sha256"
    public static let infoPlistKey = "LightwalletTlsPinSha256"
    public static let previousInfoPlistKey = "LightwalletTlsPinPreviousSha256"

    /// Default testnet ngrok/public lightwalletd TLS leaf SHA-256 pin (hex).
    public static let testnetDefaultPinHex = "d8163009e3bb0bac39adbbfeb227827a91a590b96ec33f72576278c492be628e"

    /// Resolve the primary lightwalletd leaf-cert SHA-256 pin (32 raw bytes).
    ///
    /// **Preferred (production):** set `LightwalletTlsPinSha256` in Info.plist.
    /// **Override (debug/QA):** if `UserDefaults` key `lightwallet_tls_pin_sha256`
    /// is set to a valid 64-char hex pin, it wins over Info.plist so local
    /// testing can pin a different server without rebuilding.
    ///
    /// Remote HTTPS without any pin remains **fail-closed** (S8/S12).
    public static func pinDataOrNil(
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> Data? {
        if let fromDefaults = parseHexPin(defaults.string(forKey: userDefaultsKey)) {
            return fromDefaults
        }
        return parseHexPin(bundle.object(forInfoDictionaryKey: infoPlistKey) as? String)
    }

    /// Resolve the optional previous (rotation) leaf-cert SHA-256 pin (32 raw bytes).
    /// Used during zero-downtime certificate rotation alongside the primary pin.
    public static func previousPinDataOrNil(
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> Data? {
        if let fromDefaults = parseHexPin(defaults.string(forKey: previousUserDefaultsKey)) {
            return fromDefaults
        }
        return parseHexPin(bundle.object(forInfoDictionaryKey: previousInfoPlistKey) as? String)
    }

    /// All configured pins (primary first, followed by distinct previous rotation pin if present).
    public static func allowedPins(
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> [Data] {
        var pins: [Data] = []
        if let primary = pinDataOrNil(defaults: defaults, bundle: bundle) {
            pins.append(primary)
        }
        if let previous = previousPinDataOrNil(defaults: defaults, bundle: bundle),
           !pins.contains(previous) {
            pins.append(previous)
        }
        return pins
    }

    /// Primary pin for Rust FFI bootstrap, falling back to rotation pin if primary is absent.
    public static func activePinDataOrNil(
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> Data? {
        allowedPins(defaults: defaults, bundle: bundle).first
    }

    /// Fail-closed check: returns true only when `leafCertSha256` is 32 bytes and matches
    /// either the primary pin or the previous rotation pin. Never succeeds if no pin is configured.
    public static func matches(
        leafCertSha256: Data,
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> Bool {
        guard leafCertSha256.count == 32 else { return false }
        let pins = allowedPins(defaults: defaults, bundle: bundle)
        guard !pins.isEmpty else { return false }
        return pins.contains { constantTimeEqual($0, leafCertSha256) }
    }

    /// True if `endpoint` uses TLS (`https://` or `tcp+tls://`) against a non-loopback host.
    public static func requiresPin(forEndpoint endpoint: String) -> Bool {
        let trimmed = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        guard lower.hasPrefix("https://") || lower.hasPrefix("tcp+tls://") else {
            return false
        }
        guard let parts = TorDarkfidEndpoint.parseHostPort(trimmed) else {
            // Host without explicit port: extract authority host directly.
            let rest = String(trimmed.dropFirst(lower.hasPrefix("https://") ? 8 : 10))
            let authority = rest.split(separator: "/", maxSplits: 1).first.map(String.init) ?? rest
            let host = authority.split(separator: ":").first.map(String.init) ?? authority
            return !TorDarkfidEndpoint.isLocalLoopbackHost(host)
        }
        return !TorDarkfidEndpoint.isLocalLoopbackHost(parts.host)
    }

    /// Fail-closed endpoint validation before opening a lightwalletd connection:
    /// remote HTTPS/TLS endpoints MUST have at least one valid 32-byte SHA-256 pin.
    public static func validateEndpoint(
        _ endpoint: String,
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> Bool {
        guard requiresPin(forEndpoint: endpoint) else { return true }
        return !allowedPins(defaults: defaults, bundle: bundle).isEmpty
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

    private static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for (lhsByte, rhsByte) in zip(lhs, rhs) {
            diff |= (lhsByte ^ rhsByte)
        }
        return diff == 0
    }
}
