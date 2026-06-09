//
//  HomeTests.swift
//  stealthTests
//
//  Reducer tests for Home tab selection and initial state.
//

import ComposableArchitecture
import XCTest
@testable import Home

@MainActor
final class HomeTests: XCTestCase {
    override func invokeTest() {
        withDependencies {
            HomeTestSupport.configureDependencies(&$0)
        } operation: {
            super.invokeTest()
        }
    }

    func testInitialSelectedTab_IsWallet() {
        let state = HomeTestSupport.makeState()
        XCTAssertEqual(state.selectedTab, .wallet)
    }

    func testTabSelected_UpdatesSelectedTab() async {
        let store = TestStore(
            initialState: HomeTestSupport.makeState(),
            reducer: Home.init
        ) {
            HomeTestSupport.configureDependencies(&$0)
        }
        store.exhaustivity = .off

        await store.send(.tabSelected(.transfer)) { state in
            state.selectedTab = .transfer
        }
        await store.send(.tabSelected(.chat)) { state in
            state.selectedTab = .chat
        }
        await store.send(.tabSelected(.settings)) { state in
            state.selectedTab = .settings
        }
        await store.send(.tabSelected(.wallet)) { state in
            state.selectedTab = .wallet
        }
    }
}
