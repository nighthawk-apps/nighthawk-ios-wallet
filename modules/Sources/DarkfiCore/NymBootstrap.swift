//
//  NymBootstrap.swift
//  DarkfiCore
//
//  Start the in-process Nym mixnet SOCKS proxy and wait until it reports
//  connected (Android AppNymCoordinator parity). Tor stays optional.
//

import Foundation

public enum NymBootstrap {
    public static let defaultSocksPort: UInt16 = 1080

    /// Start the proxy on `socksPort` and wait until `nymStatus()` is connected
    /// or reconnecting. Returns false on failure or timeout.
    public static func ensureReady(
        socksPort: UInt16 = defaultSocksPort,
        timeoutSeconds: Int = 180
    ) async -> Bool {
        _ = DarkfiFfiSafe.startNymProxySafely(socksPort: socksPort)
        let deadline = Date().addingTimeInterval(TimeInterval(timeoutSeconds))
        while !Task.isCancelled, Date() < deadline {
            let status = nymStatus()
            if Self.isReady(status) {
                return true
            }
            if status == "failed" {
                return false
            }
            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch {
                return false
            }
        }
        return !Task.isCancelled && Self.isReady(nymStatus())
    }

    public static func stop() {
        stopNymProxy()
    }

    private static func isReady(_ status: String) -> Bool {
        status == "connected" || status == "reconnecting"
    }
}
