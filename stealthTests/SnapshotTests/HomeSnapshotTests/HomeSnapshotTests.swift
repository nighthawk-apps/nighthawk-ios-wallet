//
//  HomeSnapshotTests.swift
//  stealthTests
//
//  Snapshot attachments for HomeView across tab selections.
//

import ComposableArchitecture
import XCTest
@testable import Home

@MainActor
final class HomeSnapshotTests: XCTestCase {
    override func invokeTest() {
        withDependencies {
            HomeTestSupport.configureDependencies(&$0)
        } operation: {
            super.invokeTest()
        }
    }

    private func captureSnapshot(selectedTab: Home.State.Tab, name: String = #function) {
        let store = Store(initialState: HomeTestSupport.makeState(selectedTab: selectedTab)) {
            Home()
        } withDependencies: {
            HomeTestSupport.configureDependencies(&$0)
        }

        withDependencies {
            HomeTestSupport.configureDependencies(&$0)
        } operation: {
            addAttachments(name: name, HomeView(store: store))
        }
    }

    func testHomeSnapshot_WalletTab() {
        captureSnapshot(selectedTab: .wallet)
    }

    func testHomeSnapshot_TransferTab() {
        captureSnapshot(selectedTab: .transfer)
    }

    func testHomeSnapshot_SettingsTab() {
        captureSnapshot(selectedTab: .settings)
    }
}
