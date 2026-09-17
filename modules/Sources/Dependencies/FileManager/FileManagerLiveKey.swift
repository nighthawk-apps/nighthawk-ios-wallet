//
//  FileManagerLiveKey.swift
//  stealth
//

import Dependencies
import Foundation

extension FileManagerClient {
    public static let live = FileManagerClient(
        url: { searchPathDirectory, searchPathDomainMask, appropriateForURL, shouldCreate in
            try FileManager.default.url(for: searchPathDirectory, in: searchPathDomainMask, appropriateFor: appropriateForURL, create: shouldCreate)
        },
        fileExists: { path in
            FileManager.default.fileExists(atPath: path)
        },
        removeItem: { url in
            try FileManager.default.removeItem(at: url)
        }
    )
}

extension FileManagerClient: DependencyKey {
    public static let liveValue: Self = .live
}
