//
//  WalletPrivacyNetworkTests.swift
//  stealthTests
//
//  Wallet network preference (Nym default) and the Nym SOCKS endpoint rewrite.
//

import DarkfiCore
import Generated
import Models
import SwiftUI
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

final class ThemeParityTests: XCTestCase {
    func testLightAndMidnightAreSelectable() {
        XCTAssertEqual(NighthawkSetting.Theme.allCases, [.cyberpunk, .dark, .midnight, .light, .paper])
        XCTAssertEqual(NighthawkSetting.Theme.light.colorScheme, .light)
        XCTAssertEqual(NighthawkSetting.Theme.midnight.colorScheme, .dark)
        XCTAssertEqual(NighthawkSetting.Theme.light.paletteOverride, .light)
        XCTAssertEqual(NighthawkSetting.Theme.midnight.paletteOverride, .midnight)
        XCTAssertFalse(NighthawkSetting.Theme.light.usesCyberpunkChrome)
        XCTAssertFalse(NighthawkSetting.Theme.midnight.usesCyberpunkChrome)
    }
}

final class PaymentRequestUriTests: XCTestCase {
    func testInvoiceIncludesAmountAndMemo() {
        let uri = PaymentRequestUri.build(address: "drk1abc", amount: "1.5", memo: "lunch & tea")
        XCTAssertTrue(uri.hasPrefix("drk:drk1abc?"))
        XCTAssertTrue(uri.contains("amount=1.5"))
        XCTAssertTrue(uri.contains("memo="))
        XCTAssertFalse(uri.contains("memo=lunch & tea"))
        let parsed = PaymentRequestUri.parse(uri)
        XCTAssertEqual(parsed?.address, "drk1abc")
        XCTAssertEqual(parsed?.amount, "1.5")
        XCTAssertEqual(parsed?.memo, "lunch & tea")
    }

    func testBareAddressWhenAmountAndMemoAreBlank() {
        XCTAssertEqual(PaymentRequestUri.build(address: "drk1abc", amount: "  ", memo: nil), "drk:drk1abc")
    }
}

final class DeviceAddressBookTests: XCTestCase {
    override func tearDown() {
        DeviceAddressBook.removeAll()
        NighthawkContactStore.removeAll()
        super.tearDown()
    }

    func testUpsertComparesBase58AddressesCaseSensitively() {
        DeviceAddressBook.removeAll()
        let first = DeviceAddressBook.upsert(label: "old", address: "Drk1abc")
        XCTAssertEqual(first.count, 1)

        // Base58 is case-sensitive: "drk1abc" is distinct from "Drk1abc".
        let distinct = DeviceAddressBook.upsert(label: "Ada", address: "drk1abc")
        XCTAssertEqual(distinct.count, 2)
        XCTAssertEqual(distinct[0].label, "Ada")
        XCTAssertEqual(distinct[0].address, "drk1abc")

        // Exact same Base58 case replaces existing entry.
        let replaced = DeviceAddressBook.upsert(label: "AdaNew", address: "drk1abc")
        XCTAssertEqual(replaced.count, 2)
        XCTAssertEqual(replaced[0].label, "AdaNew")
        XCTAssertEqual(DeviceAddressBook.load().count, 2)
    }

    func testNighthawkContactStoreAllowsWalletOnlyAndContactInviteUri() {
        NighthawkContactStore.removeAll()
        let walletOnly = NighthawkContact(
            id: "bob",
            nickname: "Bob",
            dmPublicKey: "",
            walletAddress: "fRGoBKrJuxKutPqQVGu6Mpp94uEREg6yDG9MZponXoJ1KzMGEeSAtjxm"
        )
        let saved = NighthawkContactStore.upsert(walletOnly)
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.nickname, "Bob")
        XCTAssertEqual(
            DeviceAddressBook.load().first?.address,
            "fRGoBKrJuxKutPqQVGu6Mpp94uEREg6yDG9MZponXoJ1KzMGEeSAtjxm"
        )

        let uri = NighthawkContacts.contactInviteUri(
            NighthawkContact(id: "ada", nickname: "Ada", dmPublicKey: "dmPk123", walletAddress: "drk1xyz")
        )
        XCTAssertNotNil(uri)
        let parsed = NighthawkContacts.parseInvite(uri ?? "")
        XCTAssertEqual(parsed?.nickname, "Ada")
        XCTAssertEqual(parsed?.dmPublicKey, "dmPk123")
        XCTAssertEqual(parsed?.walletAddress, "drk1xyz")
    }
}

final class FudOfferTests: XCTestCase {
    func testParseAndPolicy() {
        let uri = FudUri.parse("fud://Abcd12/notes.txt")
        XCTAssertEqual(uri?.infoHash, "abcd12")
        XCTAssertEqual(uri?.fileName, "notes.txt")
        XCTAssertNil(FudUri.parse("fud://ab/../x"))
        XCTAssertEqual(
            FudTransferPolicy.decide(enabled: true, privateTransport: true, meshOn: false, uri: uri),
            .allowed
        )
        XCTAssertEqual(
            FudTransferPolicy.decide(enabled: false, privateTransport: true, meshOn: false, uri: uri),
            .disabled
        )
        XCTAssertEqual(
            FudTransferPolicy.decide(enabled: true, privateTransport: false, meshOn: false, uri: uri),
            .needsPrivateTransport
        )
        XCTAssertEqual(FudUri.find(in: "see fud://abcd/file.bin thanks")?.fileName, "file.bin")
    }

    func testQueueWritesJson() throws {
        let uri = try XCTUnwrap(FudUri.parse("fud://abcd/file.bin"))
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let file = try FudOfferInbox.queue(uri: uri, directory: dir)
        let data = try Data(contentsOf: file)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["infoHash"] as? String, "abcd")
        XCTAssertEqual(json?["fileName"] as? String, "file.bin")
        try? FileManager.default.removeItem(at: dir)
    }
}
