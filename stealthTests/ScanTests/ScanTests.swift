//
//  ScanTests.swift
//  stealthTests
//
//  Tests for DarkFi Scan reducer: drk: URIs, raw DarkFi addresses,
//  nighthawk://contact QR invites, and invalid codes.
//

import ComposableArchitecture
import DerivationTool
import Models
import SendFlow
import URIParser
import Utils
import XCTest

@MainActor
final class ScanTests: XCTestCase {
    override func tearDown() {
        NighthawkContactStore.removeAll()
        DeviceAddressBook.removeAll()
        super.tearDown()
    }

    func testOnAppearResetsScanStatus() async {
        var initial = Scan.State()
        initial.scanStatus = .value("drk1previous".redacted)

        let store = TestStore(
            initialState: initial,
            reducer: Scan.init
        )

        await store.send(.onAppear) {
            $0.scanStatus = .unknown
        }
    }

    func testScannedInvalidValueSetsFailedStatus() async {
        let store = TestStore(
            initialState: Scan.State(),
            reducer: Scan.init
        ) {
            $0.uriParser = .liveValue
            $0.derivationTool.isDarkFiAddress = { _, _ in false }
        }

        await store.send(.scan("not-a-valid-code".redacted)) {
            $0.scanStatus = .failed
        }
    }

    func testScannedDrkPaymentUriEmitsParsedResult() async {
        let clock = TestClock()
        let address = "fRGoBKrJuxKutPqQVGu6Mpp94uEREg6yDG9MZponXoJ1KzMGEeSAtjxm"
        let uri = "drk:\(address)?amount=1.25&memo=coffee"

        let store = TestStore(
            initialState: Scan.State(),
            reducer: Scan.init
        ) {
            $0.continuousClock = clock
            $0.uriParser = .liveValue
            $0.derivationTool.isDarkFiAddress = { candidate, _ in candidate == address }
        }

        await store.send(.scan(uri.redacted)) {
            $0.scanStatus = .value(uri.redacted)
        }

        await clock.advance(by: .seconds(1))

        await store.receive(
            .delegate(
                .handleParseResult(
                    QRCodeParseResult(memo: "coffee", amount: "1.25", address: address)
                )
            )
        )
    }

    func testScannedContactInviteUpsertsContactAndEmitsInvite() async {
        NighthawkContactStore.removeAll()
        DeviceAddressBook.removeAll()

        let clock = TestClock()
        let address = "fRGoBKrJuxKutPqQVGu6Mpp94uEREg6yDG9MZponXoJ1KzMGEeSAtjxm"
        let contact = NighthawkContact(
            id: "ada",
            nickname: "Ada",
            dmPublicKey: "dmPubKeyB58",
            walletAddress: address
        )
        let inviteUri = NighthawkContacts.contactInviteUri(contact) ?? ""
        XCTAssertTrue(inviteUri.hasPrefix("nighthawk://contact"))

        let store = TestStore(
            initialState: Scan.State(),
            reducer: Scan.init
        ) {
            $0.continuousClock = clock
            $0.uriParser = .liveValue
            $0.derivationTool.isDarkFiAddress = { candidate, _ in candidate == address }
        }

        await store.send(.scan(inviteUri.redacted)) {
            $0.scanStatus = .value(inviteUri.redacted)
        }

        await clock.advance(by: .seconds(1))

        await store.receive { action in
            guard case let .delegate(.handleParseResult(result)) = action else { return false }
            return result.address == address
                && result.contactInvite?.nickname == "Ada"
                && result.contactInvite?.dmPublicKey == "dmPubKeyB58"
        }

        let stored = NighthawkContactStore.load()
        XCTAssertEqual(stored.first?.nickname, "Ada")
        XCTAssertEqual(stored.first?.dmPublicKey, "dmPubKeyB58")
    }

    func testScanFailedSetsFailedStatus() async {
        let store = TestStore(
            initialState: Scan.State(),
            reducer: Scan.init
        )

        await store.send(.scanFailed) {
            $0.scanStatus = .failed
        }
    }
}
