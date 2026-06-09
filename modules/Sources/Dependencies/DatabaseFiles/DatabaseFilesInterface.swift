//
//  DatabaseFilesInterface.swift
//  stealth
//
//  Created by Lukáš Korba on 11.11.2022.
//

import Foundation
import ComposableArchitecture

public typealias DarkFiNetwork = String

extension DependencyValues {
    public var databaseFiles: DatabaseFilesClient {
        get { self[DatabaseFilesClient.self] }
        set { self[DatabaseFilesClient.self] = newValue }
    }
}

public struct DatabaseFilesClient {
    public let documentsDirectory: () -> URL
    public let fsBlockDbRootFor: (DarkFiNetwork) -> URL
    public let cacheDbURLFor: (DarkFiNetwork) -> URL
    public let dataDbURLFor: (DarkFiNetwork) -> URL
    public let outputParamsURLFor: (DarkFiNetwork) -> URL
    public let pendingDbURLFor: (DarkFiNetwork) -> URL
    public let spendParamsURLFor: (DarkFiNetwork) -> URL
    public var torDirURLFor: (DarkFiNetwork) -> URL
    public var areDbFilesPresentFor: (DarkFiNetwork) -> Bool
}
