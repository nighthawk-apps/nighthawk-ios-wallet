//
//  DiskSpaceCheckerLiveKey.swift
//  stealth
//

import ComposableArchitecture

extension DiskSpaceCheckerClient: DependencyKey {
    public static let liveValue: Self = {
        let diskSpaceChecker = DiskSpaceChecker()
        return Self(
            freeSpaceRequiredForSync: { diskSpaceChecker.freeSpaceRequiredForSync() },
            hasEnoughFreeSpaceForSync: { diskSpaceChecker.hasEnoughFreeSpaceForSync() },
            freeSpace: { diskSpaceChecker.freeSpace() }
        )
    }()
}
