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
        documentsDirectory: XCTUnimplemented("\(Self.self).documentsDirectory", placeholder: .empty),
        fsBlockDbRootFor: XCTUnimplemented("\(Self.self).fsBlockDbRootFor", placeholder: .empty),
        cacheDbURLFor: XCTUnimplemented("\(Self.self).cacheDbURLFor", placeholder: .empty),
        dataDbURLFor: XCTUnimplemented("\(Self.self).dataDbURLFor", placeholder: .empty),
        outputParamsURLFor: XCTUnimplemented("\(Self.self).outputParamsURLFor", placeholder: .empty),
        pendingDbURLFor: XCTUnimplemented("\(Self.self).pendingDbURLFor", placeholder: .empty),
        spendParamsURLFor: XCTUnimplemented("\(Self.self).spendParamsURLFor", placeholder: .empty),
        areDbFilesPresentFor: XCTUnimplemented("\(Self.self).areDbFilesPresentFor", placeholder: false),
        nukeDbFilesFor: XCTUnimplemented("\(Self.self).nukeDbFilesFor")
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
        areDbFilesPresentFor: { _ in false },
        nukeDbFilesFor: { _ in }
    )
}
