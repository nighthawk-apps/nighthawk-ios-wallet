import XCTest
import Models
@testable import stealth_testnet

final class DarkFiExplorerTests: XCTestCase {
    func testTestnetTransactionURL() {
        let url = DarkFiExplorer.transactionURL(txid: "abc123", networkType: "testnet")
        XCTAssertEqual(url?.absoluteString, "https://explorer.testnet.dark.fi/tx/abc123")
    }

    func testMainnetTransactionURL() {
        let url = DarkFiExplorer.transactionURL(txid: "deadbeef", networkType: "mainnet")
        XCTAssertEqual(url?.absoluteString, "https://explorer.dark.fi/tx/deadbeef")
    }

    func testUnknownNetworkDefaultsToTestnet() {
        let url = DarkFiExplorer.transactionURL(txid: "aa", networkType: "localnet")
        XCTAssertEqual(url?.absoluteString, "https://explorer.testnet.dark.fi/tx/aa")
    }

    func testRejectsPathInjection() {
        XCTAssertNil(DarkFiExplorer.transactionURL(txid: "../evil", networkType: "testnet"))
        XCTAssertNil(DarkFiExplorer.transactionURL(txid: "id?x=1", networkType: "testnet"))
        XCTAssertNil(DarkFiExplorer.transactionURL(txid: "id#frag", networkType: "testnet"))
        XCTAssertNil(DarkFiExplorer.transactionURL(txid: "", networkType: "testnet"))
        XCTAssertNil(DarkFiExplorer.transactionURL(txid: "   ", networkType: "testnet"))
    }

    func testRecipientURLIsNeverInvented() {
        XCTAssertNil(
            DarkFiExplorer.recipientURL(address: "drk1qqexample", networkType: "testnet")
        )
        XCTAssertNil(
            DarkFiExplorer.recipientURL(address: "drk1qqexample", networkType: "mainnet")
        )
    }
}
