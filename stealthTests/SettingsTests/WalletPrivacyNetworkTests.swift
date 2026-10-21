//
//  WalletPrivacyNetworkTests.swift
//  stealthTests
//
//  Wallet network preference (Nym default) and the Nym SOCKS endpoint rewrite.
//

import DarkfiCore
import Models
import UserDefaults
import UserPreferencesStorage
import XCTest

final class WalletPrivacyNetworkTests: XCTestCase {
    private var defaults: UserDefaults!
    private var storage: UserPreferencesStorage!

    override func setUp() {
        super.setUp()
        let suite = "WalletPrivacyNetworkTests"
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
        storage = UserPreferencesStorage(
            icon: .default,
            defaultTheme: .default,
            currency: .off,
            selectedScreenMode: .keepOn,
            selectedSyncNotificationFrequency: .off,
            biometricsEnabled: false,
            bandit: false,
            firstSync: true,
            shownAutoshielding: false,
            useCustomLightwalletd: false,
            selectedCustomLightwalletdServer: nil,
            userDefaults: .live(userDefaults: defaults)
        )
    }

    func testFreshInstallDefaultsToNym() {
        XCTAssertEqual(storage.walletPrivacyNetwork, .nym)
        XCTAssertFalse(storage.torForWalletEnabled)
    }

    func testNetworkRoundTrip() {
        storage.setWalletPrivacyNetwork(.tor)
        XCTAssertEqual(storage.walletPrivacyNetwork, .tor)
        XCTAssertTrue(storage.torForWalletEnabled)

        storage.setWalletPrivacyNetwork(.direct)
        XCTAssertEqual(storage.walletPrivacyNetwork, .direct)
        XCTAssertFalse(storage.torForWalletEnabled)
    }

    func testUnknownStoredValueFallsBackToNym() {
        defaults.set("i2p", forKey: UserPreferencesStorage.Constants.darkfiWalletPrivacyNetwork.rawValue)
        XCTAssertEqual(storage.walletPrivacyNetwork, .nym)
    }

    func testRemoteEndpointGoesThroughNymSocksPort() {
        let url = TorDarkfidEndpoint.toConnectUrl(
            endpoint: "https://lw.example:9067",
            torEnabled: true,
            socksPort: NighthawkSetting.PrivacyNetwork.nymSocksPort
        )
        XCTAssertEqual(url, "socks5://127.0.0.1:1080/lw.example:9067")
    }

    func testLoopbackEndpointStaysDirectUnderNym() {
        let url = TorDarkfidEndpoint.toConnectUrl(
            endpoint: "tcp://127.0.0.1:9067",
            torEnabled: true,
            socksPort: NighthawkSetting.PrivacyNetwork.nymSocksPort
        )
        XCTAssertEqual(url, "tcp://127.0.0.1:9067")
    }
}
