//
//  DatabaseFilesTests.swift
//  stealthTests
//
//  Created by Lukáš Korba on 07.04.2022.
//

import XCTest
import FileManager
import Utils
import DatabaseFiles
@testable import SDKSynchronizer
@testable import stealth_testnet

class DatabaseFilesTests: XCTestCase {
    let network: DarkFiNetwork = "testnet"
    
    func testDatabaseFilesPresent() throws {
        let mockedFileManager = FileManagerClient(
            url: { _, _, _, _ in URL(fileURLWithPath: NSTemporaryDirectory()) },
            fileExists: { _ in return true },
            removeItem: { _ in }
        )
        
        let dfInteractor = DatabaseFilesClient.live(databaseFiles: DatabaseFiles(fileManager: mockedFileManager))
        let areFilesPresent = dfInteractor.areDbFilesPresentFor(network)
        XCTAssertTrue(areFilesPresent, "DatabaseFiles: `testDatabaseFilesPresent` is expected to be true but it's \(areFilesPresent)")
    }

    func testDatabaseFilesNotPresent() throws {
        let mockedFileManager = FileManagerClient(
            url: { _, _, _, _ in URL(fileURLWithPath: NSTemporaryDirectory()) },
            fileExists: { _ in return false },
            removeItem: { _ in }
        )
        
        let dfInteractor = DatabaseFilesClient.live(databaseFiles: DatabaseFiles(fileManager: mockedFileManager))
        let areFilesPresent = dfInteractor.areDbFilesPresentFor(network)
        XCTAssertFalse(areFilesPresent, "DatabaseFiles: `testDatabaseFilesNotPresent` is expected to be false but it's \(areFilesPresent)")
    }

    func testWalletRecoveryKeepsTransientSqliteErrors() {
        let messages = [
            "initialize_wallet: WalletDbError::QueryExecutionFailed",
            "WalletDbError::PragmaUpdateError",
            "DatabaseError(sqlite)",
            "Drk::new: disk I/O error (sqlite)",
            "database or disk is full",
            "wrong passphrase opening sqlite",
            "hmac check failed",
            "file is not a database: wrong key",
            "decrypt failed (sqlite_notadb)",
            "database is locked because disk is full"
        ]
        for message in messages {
            XCTAssertEqual(WalletDbRecovery.step(forNativeDrkMessage: message), .rethrow, message)
        }
    }

    func testWalletRecoveryQuarantinesConfirmedDamageAndLock() {
        let messages = [
            "file is not a database",
            "database disk image is malformed",
            "Error code sqlite_corrupt",
            "database is locked",
            "database table is locked",
            "sqlite_busy",
            "sqlite_locked",
            "malformed database",
            "could not acquire lock: file is not a database"
        ]
        for message in messages {
            XCTAssertEqual(
                WalletDbRecovery.step(forNativeDrkMessage: message),
                .quarantineWalletAndClearCache,
                message
            )
        }
        XCTAssertEqual(
            WalletDbRecovery.step(forNativeDrkMessage: "could not acquire lock"),
            .clearCacheOnly
        )
        XCTAssertEqual(
            WalletDbRecovery.step(forNativeDrkMessage: "resource temporarily unavailable"),
            .clearCacheOnly
        )
    }

    func testQuarantineWalletDatabaseRenamesBesideOriginal() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("wallet-quarantine-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let database = directory.appendingPathComponent("darkfi_wallet.db")
        let payload = Data("wallet-bytes".utf8)
        try payload.write(to: database)
        let wal = URL(fileURLWithPath: "\(database.path)-wal")
        try Data("wal".utf8).write(to: wal)

        try WalletDbRecovery.quarantineWalletDatabase(at: database.path)

        XCTAssertFalse(FileManager.default.fileExists(atPath: database.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: wal.path))
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        let quarantined = contents.filter { url in
            url.lastPathComponent.hasPrefix("darkfi_wallet.db.quarantine-")
                && !url.lastPathComponent.contains("-wal")
        }
        let quarantinedFile = try XCTUnwrap(quarantined.first)
        XCTAssertEqual(try Data(contentsOf: quarantinedFile), payload)
        let quarantinedWal = try XCTUnwrap(
            contents.first { $0.lastPathComponent.hasSuffix("-wal") }
        )
        XCTAssertEqual(try Data(contentsOf: quarantinedWal), Data("wal".utf8))

        try WalletDbRecovery.quarantineWalletDatabase(at: database.path)
    }
}
