//
//  WalletNetworkWarmStart.swift
//  SDKSynchronizer
//
//  Starts the Nym mixnet tunnel at app launch so it is (or nearly is) ready by the time the
//  wallet opens. Matches Android AppNymCoordinator.warmStartIfEnabled.
//

import DarkfiCore
import Foundation
import Models
import UserPreferencesStorage

public enum WalletNetworkWarmStart {
    public static func ensureNetworkStorageConfigured() {
        let fm = FileManager.default
        guard let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let dir = caches.appendingPathComponent("darkfi_network", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        var mutable = dir
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? mutable.setResourceValues(values)
        setNetworkStorageDir(path: dir.path)
    }

    public static func startIfNeeded() {
        ensureNetworkStorageConfigured()
        TransportHooks.setDirectDisabled(UserPreferencesStorage.live.disableDirectConnection)
        guard UserPreferencesStorage.live.walletPrivacyNetwork == .nym else { return }
        DispatchQueue.global(qos: .utility).async {
            _ = DarkfiFfiSafe.startNymProxySafely(socksPort: NighthawkSetting.PrivacyNetwork.nymSocksPort)
        }
    }
}
