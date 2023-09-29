//
//  DataManager.swift
//
//
//  Created by Matthew Watt on 9/28/23.
//
//  Taken from here: https://www.pointfree.co/collections/tours/composable-architecture-1-0/ep249-tour-of-the-composable-architecture-1-0-persistence

import ComposableArchitecture
import Foundation

public struct DataManager {
    public var load: @Sendable (URL) throws -> Data
    public var save: @Sendable (Data, URL) throws -> Void
}

extension DataManager: DependencyKey {
    public static var liveValue = Self(
        load: { url in try Data(contentsOf: url) },
        save: { data, url in try data.write(to: url) }
    )
    
    
    public static let failToWrite = Self(
        load: { _ in Data() },
        save: { _, _ in
            struct SomeError: Error {}
            throw SomeError()
        }
    )
    
    public static let failToLoad = Self(
        load: { _ in
            struct SomeError: Error {}
            throw SomeError()
        },
        save: { _, _ in }
    )
    
    public static func mock(initialData: Data? = nil) -> Self {
        let data = LockIsolated(initialData)
        return Self(
            load: { _ in
                guard let data = data.value else {
                    struct FileNotFound: Error {}
                    throw FileNotFound()
                }
                return data
            },
            save: { newData, _ in
                data.setValue(newData)
            }
        )
    }
}

extension DependencyValues {
    public var dataManager: DataManager {
        get { self[DataManager.self] }
        set { self[DataManager.self] = newValue }
    }
}

