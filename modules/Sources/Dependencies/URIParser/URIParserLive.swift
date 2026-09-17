//
//  URIParserLive.swift
//  stealth
//

import ComposableArchitecture

extension URIParserClient: DependencyKey {
    public static let liveValue = Self(
        parseDrkPaymentUri: { uri, network in
            URIParser().parseDrkPaymentUri(from: uri, network: network)
        }
    )
}
