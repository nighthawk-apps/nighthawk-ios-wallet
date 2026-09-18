import XCTest
import Utils
@testable import stealth_testnet

final class ScreenCaptureTests: XCTestCase {
    func testBoundsAreFinite() {
        let bounds = ScreenCapture.bounds
        XCTAssertTrue(bounds.width >= 0)
        XCTAssertTrue(bounds.height >= 0)
        XCTAssertFalse(bounds.width.isNaN)
        XCTAssertFalse(bounds.height.isNaN)
    }

    func testIsCapturedDoesNotTrap() {
        _ = ScreenCapture.isCaptured
    }
}
