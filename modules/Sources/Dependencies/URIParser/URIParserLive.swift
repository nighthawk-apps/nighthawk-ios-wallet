//
//  URIParserLive.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 15.11.2022.
//

import ComposableArchitecture

extension URIParserClient: DependencyKey {
    public static let liveValue = Self(
        parseZaddrOrZIP321: { uri, network in
            URIParser().parseZaddrOrZIP321(from: uri, network: network)
        }
    )
}
