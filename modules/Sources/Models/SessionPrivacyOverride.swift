//
//  SessionPrivacyOverride.swift
//  stealth
//
//  "Continue without Nym" applies for this process only — never persist .direct.
//

import Foundation

public enum SessionPrivacyOverride {
    private static let lock = NSLock()
    private static var _forceDirectThisSession = false

    /// When true, wallet/chat treat the privacy network as Direct until relaunch.
    public static var forceDirectThisSession: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _forceDirectThisSession
    }

    public static func setForceDirectThisSession(_ value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _forceDirectThisSession = value
    }

    public static func clear() {
        setForceDirectThisSession(false)
    }

    /// Resolved network for FFI prepare / routing.
    public static func resolved(
        stored: NighthawkSetting.PrivacyNetwork
    ) -> NighthawkSetting.PrivacyNetwork {
        forceDirectThisSession ? .direct : stored
    }
}
