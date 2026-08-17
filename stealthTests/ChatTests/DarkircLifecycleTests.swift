//
//  DarkircLifecycleTests.swift
//  stealthTests
//
//  Background expiration / terminate must flush sled (stop the daemon).
//  `willTerminate` is unreliable on iOS; the daemon also observes
//  `didEnterBackground` so flush does not depend on SwiftUI scenePhase.
//

import XCTest
import Home

final class DarkircLifecycleTests: XCTestCase {
    func testHandleTerminationIsIdempotent() {
        DarkircDaemonManager.shared.handleForegrounding()
        DarkircDaemonManager.shared.handleTermination()
        DarkircDaemonManager.shared.handleTermination()
        DarkircDaemonManager.shared.handleForegrounding()
    }

    func testHandleBackgroundingThenForegroundingDoesNotCrash() {
        DarkircDaemonManager.shared.handleBackgrounding()
        DarkircDaemonManager.shared.handleForegrounding()
    }
}
