//
//  DatabaseFilesTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 11.11.2022.
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay
import Utils

extension DatabaseFilesClient: TestDependencyKey {
    public static let testValue = Self(
        documentsDirectory: unimplemented("\(Self.self).documentsDirectory", placeholder: .empty),
        fsBlockDbRootFor: unimplemented("\(Self.self).fsBlockDbRootFor", placeholder: .empty),
        cacheDbURLFor: unimplemented("\(Self.self).cacheDbURLFor", placeholder: .empty),
        dataDbURLFor: unimplemented("\(Self.self).dataDbURLFor", placeholder: .empty),
        outputParamsURLFor: unimplemented("\(Self.self).outputParamsURLFor", placeholder: .empty),
        pendingDbURLFor: unimplemented("\(Self.self).pendingDbURLFor", placeholder: .empty),
        spendParamsURLFor: unimplemented("\(Self.self).spendParamsURLFor", placeholder: .empty),
        torDirURLFor: unimplemented("\(Self.self).torDirURLFor", placeholder: .empty),
        areDbFilesPresentFor: unimplemented("\(Self.self).areDbFilesPresentFor", placeholder: false)
    )
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
