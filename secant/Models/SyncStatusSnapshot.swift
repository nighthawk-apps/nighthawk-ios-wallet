//
//  SyncStatusSnapshot.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 07.07.2022.
//

import Foundation
import ZcashLightClientKit
import Generated

struct SyncStatusSnapshot: Equatable {
    let message: String
    let syncStatus: SyncStatus
    
    init(_ syncStatus: SyncStatus = .unprepared, _ message: String = "") {
        self.message = message
        self.syncStatus = syncStatus
    }
    
    static func snapshotFor(state: SyncStatus) -> SyncStatusSnapshot {
        switch state {
        case .upToDate:
            return SyncStatusSnapshot(state, L10n.Sync.Message.uptodate)
            
        case .unprepared:
            return SyncStatusSnapshot(state, L10n.Sync.Message.unprepared)
            
        case .error(let error):
            return SyncStatusSnapshot(state, L10n.Sync.Message.error(error.toZcashError().message))

        case .syncing(let progress):
            return SyncStatusSnapshot(state, L10n.Sync.Message.sync(String(format: "%0.1f", progress * 100)))
        }
    }
}

extension SyncStatusSnapshot {
    static let `default` = SyncStatusSnapshot()
}

// MARK: - Nighthawk
extension SyncStatusSnapshot {
    static func nhSnapshotFor(state: SyncStatus) -> SyncStatusSnapshot {
        switch state {
        case .enhancing:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.enhancing)
            
        case .fetching:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.fetchingUTXO)
            
        case .disconnected:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.disconnected)
            
        case .stopped:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.stopped)
            
        case .synced:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.uptodate)
            
        case .unprepared:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.unprepared)
            
        case .error(let err):
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.error(err.localizedDescription))

        case let .syncing(progress):
            if progress.progress == 0 {
                return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.preparing)
            } else if progress.progress == 100 {
                return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.finalizing)
            } else {
                return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.sync(String(format: "%0.1f", progress.progress * 100)))
            }
        }
    }
}
