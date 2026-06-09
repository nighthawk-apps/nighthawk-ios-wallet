//
//  DatabaseFilesTestKey.swift
//  stealth
//
//  Created by Lukáš Korba on 11.11.2022.
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay
import Utils

extension DatabaseFilesClient: TestDependencyKey {
    public static let testValue = Self.noOp
}

extension DatabaseFilesClient {
    public static let noOp = Self(
        documentsDirectory: { .empty },
        fsBlockDbRootFor: { _ in .empty },
        cacheDbURLFor: { _ in .empty },
        dataDbURLFor: { _ in .empty },
        outputParamsURLFor: { _ in .empty },
        pendingDbURLFor: { _ in .empty },
        spendParamsURLFor: { _ in .empty },
        torDirURLFor: { _ in .empty },
        areDbFilesPresentFor: { _ in false }
    )
}
