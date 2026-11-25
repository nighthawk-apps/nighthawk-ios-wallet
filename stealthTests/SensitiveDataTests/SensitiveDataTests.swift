//
//  SensitiveDataTests.swift
//  stealthTests
//
//  Verifies Redactable conformance and round-trip accessors for sensitive wallet models.
//

import Utils
import XCTest

final class SensitiveDataTests: XCTestCase {
    func testSeedPhraseConformsToRedactable() {
        let phrase = SeedPhrase("abandon ability able")
        XCTAssertNotNil(phrase as any Redactable)
        XCTAssertEqual(phrase.value(), "abandon ability able")
    }

    func testBirthdayConformsToRedactable() {
        let birthday = Birthday(91_808)
        XCTAssertNotNil(birthday as any Redactable)
        XCTAssertEqual(birthday.value(), 91_808)
    }

    func testRedactableStringConformsToRedactable() {
        let value = "drk1secret".redacted
        XCTAssertNotNil(value as any Redactable)
        XCTAssertEqual(value.data, "drk1secret")
    }

    func testRedactableBlockHeightConformsToRedactable() {
        let height: RedactableBlockHeight = BlockHeight(123_456).redacted
        XCTAssertNotNil(height as any Redactable)
        XCTAssertEqual(height.data, 123_456)
    }

    func testRedactableInt64ConformsToRedactable() {
        let amount = Int64(100_000_000).redacted
        XCTAssertNotNil(amount as any Redactable)
        XCTAssertEqual(amount.data, 100_000_000)
    }
}
