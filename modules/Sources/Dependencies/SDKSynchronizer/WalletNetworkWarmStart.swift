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
    public static func startIfNeeded() {
        guard UserPreferencesStorage.live.walletPrivacyNetwork == .nym else { return }
        DispatchQueue.global(qos: .utility).async {
            _ = DarkfiFfiSafe.startNymProxySafely(socksPort: NighthawkSetting.PrivacyNetwork.nymSocksPort)
        }
    }
}
