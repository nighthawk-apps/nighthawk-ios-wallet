//
//  URIParserTest.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 15.11.2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension URIParserClient: TestDependencyKey {
    public static let testValue = Self(
        parseZaddrOrZIP321: XCTUnimplemented("\(Self.self).parseZaddrOrZIP321")
    )
}
