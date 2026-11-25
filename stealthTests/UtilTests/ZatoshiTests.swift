//
//  ZatoshiTests.swift
//  stealthTests
//
//  Tests for DarkFi atomic DrkAmount formatting and decimal parsing (8 display decimals).
//

import Utils
import XCTest

final class ZatoshiTests: XCTestCase {
    func testFormattedDrkAndInputDecimalString() {
        let oneDrk: DrkAmount = 100_000_000
        XCTAssertEqual(oneDrk.inputDecimalString(), "1")
        XCTAssertEqual(oneDrk.decimalValue, NSDecimalNumber(string: "1"))

        let fractional: DrkAmount = 123_456_789
        XCTAssertEqual(fractional.inputDecimalString(), "1.23456789")

        let tiny: DrkAmount = 1
        XCTAssertEqual(tiny.inputDecimalString(), "0.00000001")

        let zero: DrkAmount = 0
        XCTAssertEqual(zero.inputDecimalString(), "0")
    }

    func testFromDecimalStringRoundTrip() {
        XCTAssertEqual(DrkAmount.fromDecimalString("1"), 100_000_000)
        XCTAssertEqual(DrkAmount.fromDecimalString("0.5"), 50_000_000)
        XCTAssertEqual(DrkAmount.fromDecimalString("0.00000001"), 1)
        XCTAssertEqual(DrkAmount.from(decimalString: "2.25"), 225_000_000)
        XCTAssertNil(DrkAmount.fromDecimalString("not-a-number"))
    }

    func testAddingAndSubtractingAtomicDrkAmounts() {
        let amountA: DrkAmount = 100_000
        let amountB: DrkAmount = 200_000
        XCTAssertEqual(amountA + amountB, 300_000)
        XCTAssertEqual(amountB - amountA, 100_000)
        XCTAssertEqual(amountA - amountB, -100_000)
    }

    func testCustomDecimalsSupport() {
        let sixDecimals: DrkAmount = 1_500_000
        XCTAssertEqual(sixDecimals.inputDecimalString(decimals: 6), "1.5")
        XCTAssertEqual(DrkAmount.fromDecimalString("1.5", decimals: 6), 1_500_000)
    }
}
