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
    }
}
