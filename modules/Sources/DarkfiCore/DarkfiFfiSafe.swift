import Foundation

/// Safe wrappers around UniFFI Arti Tor and Nym mixnet exports.
///
/// Captures module-level UniFFI free functions before `DarkfiFfiSafe` method
/// names would shadow them.
private let ffiIsArtiRunning: () -> Bool = { isArtiRunning() }
private let ffiStopArtiProxy: () -> Void = { stopArtiProxy() }
private let ffiStartArtiProxy: (String) throws -> Bool = { try startArtiProxy(socksListen: $0) }
private let ffiIsNymRunning: () -> Bool = { isNymRunning() }
private let ffiNymStatus: () -> String = { nymStatus() }
private let ffiStopNymProxy: () -> Void = { stopNymProxy() }
private let ffiStartNymProxy: (String) throws -> Bool = { try startNymProxy(socksListen: $0) }

public struct DarkfiFfiSafe {
    public static func isArtiRunning() -> Bool {
        ffiIsArtiRunning()
    }

    public static func startArtiProxySafely(socksPort: UInt16) -> Bool {
        do {
            return try ffiStartArtiProxy(String(socksPort))
        } catch {
            return false
        }
    }

    public static func stopArtiProxy() {
        ffiStopArtiProxy()
    }

    /// True only once the Nym mixnet tunnel has genuinely come up.
    public static func isNymRunning() -> Bool {
        ffiIsNymRunning()
    }

    /// Starts the Nym SOCKS proxy in the background. Poll `isNymRunning()` for readiness.
    public static func startNymProxySafely(socksPort: UInt16) -> Bool {
        do {
            return try ffiStartNymProxy(String(socksPort))
        } catch {
            return false
        }
    }

    public static func stopNymProxy() {
        ffiStopNymProxy()
    }

    /// `stopped` | `bootstrapping` | `connected` | `reconnecting` | `failed`.
    public static func nymStatus() -> String {
        ffiNymStatus()
    }
}
