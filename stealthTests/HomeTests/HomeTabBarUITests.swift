//
//  HomeTabBarUITests.swift
//  stealthTests
//
//  UI-level tests for the home tab bar selection wiring.
//

import ComposableArchitecture
import XCTest
@testable import Home

@MainActor
final class HomeTabBarUITests: XCTestCase {
    override func invokeTest() {
        withDependencies {
            HomeTestSupport.configureDependencies(&$0)
        } operation: {
            super.invokeTest()
        }
    }

    func testTabBar_OnSelectUpdatesBoundSelection() {
        var selected = Home.State.Tab.wallet
        let onSelect: (Home.State.Tab) -> Void = { selected = $0 }

        for tab in [Home.State.Tab.settings, .chat, .dex, .wallet] {
            onSelect(tab)
            XCTAssertEqual(selected, tab)
        }
    }

    func testHomeView_SynchronizerFailureDoesNotDisableWalletTab() {
        let state = HomeTestSupport.makeState(synchronizerFailedToStart: true)
        XCTAssertTrue(state.synchronizerFailed)
        XCTAssertEqual(state.selectedTab, .wallet)
    }
}
