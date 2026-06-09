//
//  DatabaseFiles.swift
//  stealth
//
//  Created by Lukáš Korba on 05.04.2022.
//

import Foundation
import FileManager

public struct DatabaseFiles {
    enum DatabaseFilesError: Error {
        case getFsBlockDbRoot
        case getDocumentsURL
        case getCacheURL
        case getDataURL
        case getOutputParamsURL
        case getPendingURL
        case getSpendParamsURL
        case filesPresentCheck
    }
    
    private let fileManager: FileManagerClient
    
    public init(fileManager: FileManagerClient) {
        self.fileManager = fileManager
    }
    
    func documentsDirectory() -> URL {
        do {
            return try fileManager.url(.documentDirectory, .userDomainMask, nil, true)
        } catch {
            // This is not super clean but this is second best thing when the above call fails.
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        }
    }

    func cacheDbURL(for network: DarkFiNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network)-cache.db",
                isDirectory: false
            )
    }

    func dataDbURL(for network: DarkFiNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network)-data.db",
                isDirectory: false
                )
    }

    func outputParamsURL(for network: DarkFiNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network)-sapling-output.params",
                isDirectory: false
            )
    }

    func pendingDbURL(for network: DarkFiNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network)-pending.db",
                isDirectory: false
            )
    }

    func spendParamsURL(for network: DarkFiNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network)-sapling-spend.params",
                isDirectory: false
            )
    }
    
    func toDirURL(for network: DarkFiNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network)-to-dir",
                isDirectory: false
            )
    }

    func areDbFilesPresent(for network: DarkFiNetwork) -> Bool {
        let dataDbURL = dataDbURL(for: network)
        return fileManager.fileExists(dataDbURL.path)
    }
}
