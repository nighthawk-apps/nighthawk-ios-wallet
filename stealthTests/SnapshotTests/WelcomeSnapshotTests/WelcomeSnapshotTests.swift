//
//  WelcomeSnapshotTests.swift
//  stealthTests
//

import XCTest
import ComposableArchitecture
import Welcome
@testable import stealth_testnet

class WelcomeSnapshotTests: XCTestCase {
    func testWelcomeSnapshot() throws {
        let store = Store(
            initialState: Welcome.State(),
            reducer: Welcome.init
        )

        addAttachments(WelcomeView(store: store))
    }
}
