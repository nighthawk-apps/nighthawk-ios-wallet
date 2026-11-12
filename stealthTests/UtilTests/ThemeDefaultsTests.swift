//
//  ThemeDefaultsTests.swift
//  stealthTests
//

import Models
import XCTest
@testable import Home

final class ThemeDefaultsTests: XCTestCase {
    func testSelectableThemesMatchAndroidVariants() {
        XCTAssertEqual(
            NighthawkSetting.Theme.selectableCases,
            [.cyberpunk, .stealth, .light, .paper, .midnight]
        )
    }

    func testLegacyDefaultMapsToCyberpunk() {
        XCTAssertEqual(NighthawkSetting.Theme.default.canonical, .cyberpunk)
        XCTAssertTrue(NighthawkSetting.Theme.default.usesCyberpunkWallpaper)
    }

    func testLegacyDarkMapsToStealth() {
        XCTAssertEqual(NighthawkSetting.Theme.dark.canonical, .stealth)
        XCTAssertFalse(NighthawkSetting.Theme.dark.usesCyberpunkWallpaper)
    }
}
