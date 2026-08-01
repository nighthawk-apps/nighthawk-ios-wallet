//
//  TorDarkfidEndpoint.swift
//  DarkfiCore
//
//  Rewrites lightwallet / darkfid endpoint URLs for Rust dialers when Tor is on.
//  Mirrors Android TorDarkfidEndpoint.kt.
//
//  Non-loopback tcp/http(s) → socks5://proxyHost:proxyPort/destHost:destPort
//

import Foundation

public enum TorDarkfidEndpoint {
    public static let defaultSocksHost = "127.0.0.1"
    public static let defaultSocksPort: UInt16 = 9050

    /// Whether `host` is loopback (direct dial even when Tor is enabled).
    public static func isLocalLoopbackHost(_ host: String) -> Bool {
        let h = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = h.isEmpty ? defaultSocksHost : h
        return resolved == "127.0.0.1"
            || resolved.caseInsensitiveCompare("localhost") == .orderedSame
            || resolved == "::1"
            || resolved == defaultSocksHost
    }

    /// Plain URL when Tor is off or host is loopback; otherwise DarkFi
    /// `socks5://proxy:port/dest:port` transport URI for the Rust FFI.
    public static func toConnectUrl(
        endpoint: String,
        torEnabled: Bool,
        socksHost: String = defaultSocksHost,
        socksPort: UInt16 = defaultSocksPort
    ) -> String {
        var url = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return url }

        if !url.contains("://") {
            url = "tcp://\(url)"
        }

        // Already a SOCKS transport URI — leave as-is.
        if url.lowercased().hasPrefix("socks5://") {
            return url
        }

        guard let parts = parseHostPort(url) else {
            return url
        }

        if !torEnabled || isLocalLoopbackHost(parts.host) {
            return url
        }

        let proxyHost = socksHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedProxy = proxyHost.isEmpty ? defaultSocksHost : proxyHost
        return "socks5://\(resolvedProxy):\(socksPort)/\(parts.host):\(parts.port)"
    }

    /// Extract host + port from tcp/http(s)/tcp+tls URLs.
    public static func parseHostPort(_ url: String) -> (host: String, port: UInt16)? {
        guard let schemeRange = url.range(of: "://") else { return nil }
        let rest = String(url[schemeRange.upperBound...])
        // Drop path/query if present (socks5 dest has no path).
        let authority = rest.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? rest

        // host:port or [ipv6]:port
        if authority.hasPrefix("["), let close = authority.firstIndex(of: "]") {
            let host = String(authority[authority.index(after: authority.startIndex)..<close])
            let after = authority[authority.index(after: close)...]
            guard after.hasPrefix(":"), let port = UInt16(after.dropFirst()) else { return nil }
            return (host, port)
        }

        guard let colon = authority.lastIndex(of: ":") else { return nil }
        let host = String(authority[..<colon])
        guard let port = UInt16(authority[authority.index(after: colon)...]), !host.isEmpty else {
            return nil
        }
        return (host, port)
    }
}
