//
//  DarkircLifecycleTests.swift
//  stealthTests
//
//  Background / terminate must flush sled (stop the daemon).
//  `didEnterBackground` drains immediately so sockets are not frozen.
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
