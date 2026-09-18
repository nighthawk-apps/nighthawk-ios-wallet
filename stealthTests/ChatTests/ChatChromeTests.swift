//
//  ChatChromeTests.swift
//  stealthTests
//
//  Stealth chat chroma: own nick, hashed peers, two-tone body, encrypted threads.
//

import XCTest
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

    func testEncryptedChannelStoreReplacesSameName() {
        let json = EncryptedChannelStore.upsert(name: "#dev", secret: "s1", json: nil)
        let json2 = EncryptedChannelStore.upsert(name: "#dev", secret: "s2", json: json)
        let rows = EncryptedChannelStore.load(json: json2)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.sharedSecret, "s2")
    }
}
