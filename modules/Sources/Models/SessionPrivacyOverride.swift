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

    private static var isDirectDisabled: Bool {
        UserDefaults.standard.bool(forKey: "darkfiDisableDirectConnection")
    }

    /// When true, wallet/chat treat the privacy network as Direct until relaunch.
    public static var forceDirectThisSession: Bool {
        if isDirectDisabled { return false }
        lock.lock()
        defer { lock.unlock() }
        return _forceDirectThisSession
    }

    public static func setForceDirectThisSession(_ value: Bool) {
        if value && isDirectDisabled { return }
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
        if isDirectDisabled {
            return stored == .direct ? .nym : stored
        }
        return forceDirectThisSession ? .direct : stored
    }
}
