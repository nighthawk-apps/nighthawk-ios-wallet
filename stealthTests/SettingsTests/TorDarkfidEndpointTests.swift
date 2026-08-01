//
//  TorDarkfidEndpointTests.swift
//  stealthTests
//

import DarkfiCore
import XCTest

final class TorDarkfidEndpointTests: XCTestCase {
    func testPassthroughWhenTorOff() {
        let url = TorDarkfidEndpoint.toConnectUrl(
            endpoint: "tcp://relay.example:18345",
            torEnabled: false
        )
        XCTAssertEqual(url, "tcp://relay.example:18345")
    }

    func testLoopbackUnwrappedWhenTorOn() {
        let url = TorDarkfidEndpoint.toConnectUrl(
            endpoint: "tcp://127.0.0.1:18345",
            torEnabled: true
        )
        XCTAssertEqual(url, "tcp://127.0.0.1:18345")
    }

    func testSocks5WhenTorOnAndRemoteHost() {
        let url = TorDarkfidEndpoint.toConnectUrl(
            endpoint: "tcp://node.dark.fi:18345",
            torEnabled: true
        )
        XCTAssertEqual(url, "socks5://127.0.0.1:9050/node.dark.fi:18345")
    }

    func testHttpsRewrittenToSocks5() {
        let url = TorDarkfidEndpoint.toConnectUrl(
            endpoint: "https://lw.example:9067",
            torEnabled: true,
            socksHost: "10.0.0.5",
            socksPort: 9150
        )
        XCTAssertEqual(url, "socks5://10.0.0.5:9150/lw.example:9067")
    }

    func testAlreadySocks5LeftAlone() {
        let url = TorDarkfidEndpoint.toConnectUrl(
            endpoint: "socks5://127.0.0.1:9050/node.dark.fi:9067",
            torEnabled: true
        )
        XCTAssertEqual(url, "socks5://127.0.0.1:9050/node.dark.fi:9067")
    }
}
