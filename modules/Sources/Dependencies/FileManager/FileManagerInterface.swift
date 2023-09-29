//
//  FileManagerClient.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 07.04.2022.
//

import Dependencies
import Foundation

public struct FileManagerClient {
    public let url: (FileManager.SearchPathDirectory, FileManager.SearchPathDomainMask, URL?, Bool) throws -> URL
    public let fileExists: (String) -> Bool
    public let removeItem: (URL) throws -> Void
    
    public init(
        url: @escaping (FileManager.SearchPathDirectory, FileManager.SearchPathDomainMask, URL?, Bool) throws -> URL,
        fileExists: @escaping (String) -> Bool,
        removeItem: @escaping (URL) throws -> Void)
    {
        self.url = url
        self.fileExists = fileExists
        self.removeItem = removeItem
    }
}

extension DependencyValues {
    public var fileManager: FileManagerClient {
        get { self[FileManagerClient.self] }
        set { self[FileManagerClient.self] = newValue }
    }
}
