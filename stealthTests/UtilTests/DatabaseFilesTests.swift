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
}
