//
//  URIParserTest.swift
//  stealth
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension URIParserClient: TestDependencyKey {
    public static let testValue = Self(
        parseDrkPaymentUri: unimplemented("\(Self.self).parseDrkPaymentUri", placeholder: .failed)
    )
}
