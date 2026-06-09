//
//  URIParserClient.swift
//  stealth
//
//  Created by Lukáš Korba on 17.05.2022.
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
    public var parseZaddrOrZIP321: (String, String) -> QRCodeParseResult
}
        
