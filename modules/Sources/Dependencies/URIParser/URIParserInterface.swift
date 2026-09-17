//
//  URIParserClient.swift
//  stealth
//

import Foundation
import ComposableArchitecture

extension DependencyValues {
    public var uriParser: URIParserClient {
        get { self[URIParserClient.self] }
        set { self[URIParserClient.self] = newValue }
    }
}

public struct URIParserClient {
    public var parseDrkPaymentUri: (String, String) -> QRCodeParseResult
}
