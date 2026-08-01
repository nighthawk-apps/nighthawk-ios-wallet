import Foundation

/// Safe wrappers around UniFFI Arti Tor exports.
///
/// Captures module-level UniFFI free functions before `DarkfiFfiSafe` method
/// names would shadow them.
private let ffiIsArtiRunning: () -> Bool = { isArtiRunning() }
private let ffiStopArtiProxy: () -> Void = { stopArtiProxy() }
private let ffiStartArtiProxy: (String) throws -> Bool = { try startArtiProxy(socksListen: $0) }

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
}
