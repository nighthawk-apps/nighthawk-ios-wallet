//
//  PartnersTestKey.swift
//  
//
//  Created by Two Point on 7/19/23.
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension PartnersClient: TestDependencyKey {
    public static let testValue = Self(
        sideshiftURL: XCTUnimplemented("\(Self.self).sideshiftURL", placeholder: nil),
        stealthexURL: XCTUnimplemented("\(Self.self).stealthexURL", placeholder: nil)
    )
}
