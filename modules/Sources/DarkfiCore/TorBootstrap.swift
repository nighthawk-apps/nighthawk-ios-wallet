//
//  TorBootstrap.swift
//  DarkfiCore
//
//  Start embedded Arti and wait until bootstrap reports ready (Android
//  AppTorCoordinator / wait_until_running parity).
//

import Foundation

public enum TorBootstrap {
    /// Start Arti on `socksPort` (if needed) and wait until `isArtiRunning()`.
    /// Returns `true` when Tor is ready within `timeoutSeconds`.
    public static func ensureReady(
        socksPort: UInt16,
        timeoutSeconds: Int = 120
    ) async -> Bool {
        _ = DarkfiFfiSafe.startArtiProxySafely(socksPort: socksPort)
        if DarkfiFfiSafe.isArtiRunning() {
            return true
        }
        let deadline = Date().addingTimeInterval(TimeInterval(timeoutSeconds))
        while Date() < deadline {
            if DarkfiFfiSafe.isArtiRunning() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(500))
        }
        return DarkfiFfiSafe.isArtiRunning()
    }
}
