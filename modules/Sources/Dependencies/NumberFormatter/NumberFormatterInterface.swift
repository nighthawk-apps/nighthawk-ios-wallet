//
//  AppVersionInterface.swift
//  stealth
//

import Foundation
import ComposableArchitecture

extension DependencyValues {
    public var numberFormatter: NumberFormatterClient {
        get { self[NumberFormatterClient.self] }
        set { self[NumberFormatterClient.self] = newValue }
    }
}

public struct NumberFormatterClient {
    public var string: (NSDecimalNumber) -> String?
    public var number: (String) -> NSNumber?
}
