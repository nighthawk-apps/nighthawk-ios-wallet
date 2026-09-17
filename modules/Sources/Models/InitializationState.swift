//
//  InitializationState.swift
//  stealth
//

import Foundation

public enum InitializationState: Equatable {
    case failed
    case initialized
    case needsMigration
    case keysMissing
    case filesMissing
    case uninitialized
}

public enum SDKInitializationError: Error {
    case failed
}
