//
//  SyncStatusSnapshot.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 07.07.2022.
//

import Foundation
import ZcashLightClientKit
import Generated

public struct SyncStatusSnapshot: Equatable {
    public let message: String
    public let syncStatus: SyncStatus
    
    public init(_ syncStatus: SyncStatus = .unprepared, _ message: String = "") {
        self.message = message
        self.syncStatus = syncStatus
    }
    
    public static func snapshotFor(state: SyncStatus) -> SyncStatusSnapshot {
        switch state {
        case .upToDate:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.uptodate)
            
        case .unprepared:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.unprepared)
            
        case .error(let error):
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.error(error.toZcashError().message))

        case .syncing(let progress):
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.sync(String(format: "%0.1f", progress * 100)))
        }
    }
}

extension SyncStatusSnapshot {
    public static let `default` = SyncStatusSnapshot()
}

// MARK: - Nighthawk
public extension SyncStatusSnapshot {
    static func nhSnapshotFor(state: SyncStatus) -> SyncStatusSnapshot {
        switch state {
        case .upToDate:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.uptodate)
        case .unprepared:
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.unprepared)
        case .error(let err):
            return SyncStatusSnapshot(state, L10n.Nighthawk.Sync.Message.error(err.localizedDescription))
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
    
    var isSyncFailed: Bool {
        if case .error = syncStatus {
            return true
        }
        
        return false
    }
}
