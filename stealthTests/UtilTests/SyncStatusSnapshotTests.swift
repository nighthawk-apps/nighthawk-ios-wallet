//
//  SyncStatusSnapshotTests.swift
//  stealthTests
//

import Models
import Utils
import XCTest
@testable import Home

final class SyncStatusSnapshotTests: XCTestCase {
    func testUpToDateUsesSyncedBlockLabelWhenTipKnown() {
        let state = SynchronizerState(
            syncStatus: .upToDate,
            confirmedBalance: 0,
            latestBlockHeight: 42_000
        )
        let snapshot = SyncStatusSnapshot.snapshotFor(state: state)
        XCTAssertEqual(snapshot.lightSyncStatusMessage, "Synced · Block 42000")
    }

    func testLightStatusMessageWinsOverSyncedBlockFallback() {
        let state = SynchronizerState(
            syncStatus: .upToDate,
            confirmedBalance: 0,
            latestBlockHeight: 42_000,
            lightStatusMessage: "Synced · lightwalletd tip is 10 blocks behind darkfid"
        )
        let snapshot = SyncStatusSnapshot.snapshotFor(state: state)
        XCTAssertEqual(
            snapshot.lightSyncStatusMessage,
            "Synced · lightwalletd tip is 10 blocks behind darkfid"
        )
    }
}
