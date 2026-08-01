//
//  SyncStatusSnapshot.swift
//  stealth
//
//  Created by Lukáš Korba on 07.07.2022.
//

import Foundation
import Generated
import Utils

public struct SyncStatusSnapshot: Equatable {
    public let message: String
    public let syncStatus: SyncStatus

    /// Human-readable sync status from lightwallet engine (e.g. "Syncing block 42 of 1000")
    public let lightSyncStatusMessage: String?
    /// Human-readable sync type label (e.g. "OMR", "Trial decryption")
    public let lightSyncTypeMessage: String?
    /// Whether OMR is available on the connected lightwallet server
    public let omrAvailable: Bool
    /// Canonical retrieval/encryption path currently in use (shared Rust model).
    public let syncMethod: DarkfiSyncMethod

    public init(
        _ syncStatus: SyncStatus = .unprepared,
        _ message: String = "",
        lightSyncStatusMessage: String? = nil,
        lightSyncTypeMessage: String? = nil,
        omrAvailable: Bool = false,
        syncMethod: DarkfiSyncMethod = .unknown
    ) {
        self.message = message
        self.syncStatus = syncStatus
        self.lightSyncStatusMessage = lightSyncStatusMessage
        self.lightSyncTypeMessage = lightSyncTypeMessage
        self.omrAvailable = omrAvailable
        self.syncMethod = syncMethod
    }

    public static func snapshotFor(state: SyncStatus) -> SyncStatusSnapshot {
        switch state {
        case .upToDate:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.uptodate)
        case .unprepared:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.unprepared)
        case .error(let err):
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.error(err.localizedDescription))
        case .stopped:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.stopped)
        case let .syncing(progress):
            let percent = progress * 100
            if percent == 0 {
                return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.preparing)
            } else if percent == 100 {
                return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.finalizing)
            } else {
                return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.sync(String(format: "%0.1f", percent)))
            }
        }
    }

    /// Create a snapshot enriched with lightwallet sync state.
    public static func snapshotFor(
        state: SyncStatus,
        lightStatusMessage: String?,
        lightTypeMessage: String?,
        omrAvailable: Bool,
        syncMethod: DarkfiSyncMethod = .unknown
    ) -> SyncStatusSnapshot {
        let base = snapshotFor(state: state)
        return SyncStatusSnapshot(
            base.syncStatus,
            base.message,
            lightSyncStatusMessage: lightStatusMessage,
            lightSyncTypeMessage: lightTypeMessage,
            omrAvailable: omrAvailable,
            syncMethod: syncMethod
        )
    }

    /// Convenience: enrich a snapshot with the live sync method drawn from the
    /// synchronizer state (used by the home-screen indicator).
    public static func snapshotFor(state: SynchronizerState) -> SyncStatusSnapshot {
        snapshotFor(
            state: state.syncStatus,
            lightStatusMessage: nil,
            lightTypeMessage: state.activeSyncMethod == .unknown ? nil : state.activeSyncMethod.displayName,
            omrAvailable: state.activeSyncMethod.isPrivateRetrieval,
            syncMethod: state.activeSyncMethod
        )
    }

    public var isSyncFailed: Bool {
        if case .error = syncStatus {
            return true
        }

        return false
    }
}

extension SyncStatusSnapshot {
    public static let `default` = SyncStatusSnapshot()
}
