//
//  DiskSpaceCheckerMocks.swift
//  stealth
//

extension DiskSpaceCheckerClient {
    public static let mockEmptyDisk = DiskSpaceCheckerClient(
        freeSpaceRequiredForSync: { 1024 },
        hasEnoughFreeSpaceForSync: { true },
        freeSpace: { 2048 }
    )

    public static let mockFullDisk = DiskSpaceCheckerClient(
        freeSpaceRequiredForSync: { 1024 },
        hasEnoughFreeSpaceForSync: { false },
        freeSpace: { 0 }
    )
}
