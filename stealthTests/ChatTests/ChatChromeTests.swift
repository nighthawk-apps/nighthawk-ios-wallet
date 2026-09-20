//
//  ChatChromeTests.swift
//  stealthTests
//
//  Stealth chat chroma: own nick, hashed peers, two-tone body, encrypted threads.
//

import XCTest
import Utils
@testable import Home

final class ChatChromeTests: XCTestCase {
    func testOwnNickUsesAccentNotPeerHash() {
        XCTAssertTrue(ChatChrome.isOwnNick("HawkOne", myNick: "hawkone"))
        XCTAssertEqual(ChatChrome.peerNickIndex("alice"), ChatChrome.peerNickIndex("ALICE"))
        XCTAssertEqual(ChatChrome.bodyColor(isOwn: true), ChatChrome.bodyOutgoing)
        XCTAssertEqual(ChatChrome.bodyColor(isOwn: false), ChatChrome.bodyIncoming)
    }

    func testThreadIsEncryptedDirectAndSecretChannels() {
        XCTAssertTrue(ChatChrome.threadIsEncrypted(isDirectInbox: true, threadKey: "alice", encryptedChannelNames: []))
        XCTAssertTrue(
            ChatChrome.threadIsEncrypted(
                isDirectInbox: false,
                threadKey: "#dev",
                encryptedChannelNames: ["#Dev"]
            )
        )
        XCTAssertFalse(
            ChatChrome.threadIsEncrypted(
                isDirectInbox: false,
                threadKey: "#dev",
                encryptedChannelNames: []
            )
        )
    }

    func testEncryptedChannelIndexParsesNames() {
        let json = ##"[{"id":"1","name":"#dev","sharedSecret":"abc","topic":""}]"##
        XCTAssertEqual(EncryptedChannelIndex.names(from: json), ["#dev"])
        XCTAssertTrue(EncryptedChannelIndex.names(from: nil).isEmpty)
    }

    func testLexerSplitsUrlsAndFud() {
        let spans = ChatMessageLexer.lex("see https://dark.fi/docs and fud://QmHash/file.png thanks.")
        XCTAssertEqual(spans.first, .text("see "))
        XCTAssertEqual(spans.dropFirst().first, .url("https://dark.fi/docs"))
        XCTAssertTrue(ChatMessageLexer.hasFud("fud://abc"))
        XCTAssertEqual(ChatMessageLexer.fudUris("fud://QmHash/file.png"), ["fud://QmHash/file.png"])
        XCTAssertEqual(
            ChatMessageLexer.invoiceUris("pay drk:addr?amount=1 now"),
            ["drk:addr?amount=1"]
        )
    }

    func testFudUriParseAndPolicy() {
        let uri = FudUri.parse("fud://abcdef012345/file.png")
        XCTAssertEqual(uri?.infoHash, "abcdef012345")
        XCTAssertEqual(uri?.fileName, "file.png")
        XCTAssertNil(FudUri.parse("fud://ab/file.png"))
        XCTAssertNil(FudUri.parse("fud://abcdef01/../secret"))
        XCTAssertEqual(
            FudTransferPolicy.decide(enabled: false, torReady: true, meshOn: false, uri: uri),
            .disabled
        )
        XCTAssertEqual(
            FudTransferPolicy.decide(enabled: true, torReady: false, meshOn: false, uri: uri),
            .needsPrivateTransport
        )
        XCTAssertEqual(
            FudTransferPolicy.decide(enabled: true, torReady: true, meshOn: false, uri: uri),
            .allowed
        )
        XCTAssertEqual(
            FudTransferPolicy.decide(enabled: true, torReady: false, meshOn: true, uri: uri),
            .allowed
        )
    }

    func testPeerHostDisplayParsesDnsNames() {
        XCTAssertEqual(
            PeerHostDisplay.hostFromUrl("tcp+tls://seed.testnet.dark.fi:25588"),
            "seed.testnet.dark.fi"
        )
        XCTAssertEqual(PeerHostDisplay.hostFromUrl("tcp://1.2.3.4:9601"), "1.2.3.4")
        XCTAssertEqual(PeerHostDisplay.hostFromUrl("tcp+tls://[2001:db8::1]:9601"), "2001:db8::1")
        XCTAssertEqual(PeerHostDisplay.hostFromUrl("tor://abc.onion:9601"), "abc.onion")
        XCTAssertNil(PeerHostDisplay.hostFromUrl(nil))
        XCTAssertNil(PeerHostDisplay.hostFromUrl("connected"))

        XCTAssertEqual(
            PeerHostDisplay.dnsName(
                url: "tcp+tls://lilith0.dark.fi:25588",
                placeholder: "sleeping",
                reverseLookup: { _ in XCTFail("must not reverse-lookup hostnames"); return nil }
            ),
            "lilith0.dark.fi"
        )
        XCTAssertEqual(
            PeerHostDisplay.dnsName(
                url: "tor://abcxyz.onion:9601",
                placeholder: "connected",
                reverseLookup: { _ in XCTFail("must not reverse-lookup onion"); return nil }
            ),
            "abcxyz.onion"
        )
        XCTAssertEqual(
            PeerHostDisplay.dnsName(
                url: "tcp://8.8.8.8:9601",
                placeholder: "connected",
                reverseLookup: { _ in
                    XCTFail("must not reverse-lookup IPs")
                    return "dns.google"
                }
            ),
            PeerHostDisplay.opaquePeerLabel
        )
        XCTAssertEqual(
            PeerHostDisplay.dnsName(
                url: "tcp://10.0.0.1:1",
                placeholder: "connected",
                reverseLookup: { _ in
                    XCTFail("must not reverse-lookup IPs")
                    return nil
                }
            ),
            PeerHostDisplay.opaquePeerLabel
        )
        XCTAssertNotEqual(
            PeerHostDisplay.dnsName(
                url: "tcp+tls://[2001:db8::1]:9601",
                placeholder: "connected",
                reverseLookup: { _ in
                    XCTFail("must not reverse-lookup IPs")
                    return nil
                }
            ),
            "2001:db8::1"
        )
        XCTAssertEqual(
            PeerHostDisplay.dnsName(url: nil, placeholder: "sleeping", reverseLookup: { _ in nil }),
            "sleeping"
        )
        XCTAssertTrue(PeerHostDisplay.isIpLiteral("1.2.3.4"))
        XCTAssertTrue(PeerHostDisplay.isIpLiteral("2001:db8::1"))
        XCTAssertFalse(PeerHostDisplay.isIpLiteral("seed.dark.fi"))
        XCTAssertTrue(PeerHostDisplay.isOnion("abc.onion"))
    }

    func testDarkfiAddressAndAmountHelpers() {
        XCTAssertFalse(DarkfiAddressFormat.isValid("", network: "testnet"))
        XCTAssertFalse(DarkfiAddressFormat.isValid("not-an-address", network: "testnet"))
        XCTAssertEqual(LightwalletdURL.parse("https://lwd.example.com:443")?.scheme, "https")
        XCTAssertEqual(LightwalletdURL.parse("lwd.example.com:9067")?.port, 9067)
        XCTAssertEqual(DrkAmount.fromDecimalString("1.5"), 150_000_000)
        XCTAssertNil(DrkAmount.fromDecimalString("abc"))
    }

    func testEncryptedChannelStoreReplacesSameName() {
        let json = EncryptedChannelStore.upsert(name: "#dev", secret: "s1", json: nil)
        let json2 = EncryptedChannelStore.upsert(name: "#dev", secret: "s2", json: json)
        let rows = EncryptedChannelStore.load(json: json2)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.sharedSecret, "s2")
    }
}
