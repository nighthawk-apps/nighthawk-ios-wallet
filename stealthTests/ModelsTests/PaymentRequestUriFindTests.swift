import Models
import XCTest

final class PaymentRequestUriFindTests: XCTestCase {
    func testFindDrkInvoiceInChatLine() {
        let line = "please pay drk:drk1abc?amount=1.25&memo=bHVuY2g thanks"
        let parsed = PaymentRequestUri.find(in: line)
        XCTAssertEqual(parsed?.address, "drk1abc")
        XCTAssertEqual(parsed?.amount, "1.25")
        XCTAssertEqual(parsed?.memo, "lunch")
    }

    func testInviteUriRoundTrip() {
        let contact = NighthawkContact(
            id: "alice",
            nickname: "alice",
            dmPublicKey: "deadbeef",
            walletAddress: "drk1xyz"
        )
        XCTAssertEqual(NighthawkContacts.inviteUri(contact), "drk:drk1xyz")
        let parsed = NighthawkContacts.parseInvite(NighthawkContacts.inviteUri(contact) ?? "")
        XCTAssertEqual(parsed?.walletAddress, "drk1xyz")
        XCTAssertFalse(NighthawkContacts.safetyNumber(dmPublicKey: "deadbeef", walletAddress: "drk1xyz").isEmpty)
    }

    func testClearnetLinkGuard() {
        XCTAssertTrue(ChatLinkGuard.isClearnetHttp("https://example.com"))
        XCTAssertFalse(ChatLinkGuard.isClearnetHttp("drk:drk1abc"))
    }
}
