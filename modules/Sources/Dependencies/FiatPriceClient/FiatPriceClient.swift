//
//  FiatPriceClient.swift
//
//
//  Created by Matthew Watt on 10/1/23.
//

import ComposableArchitecture
import Foundation
import Models
import Utils

public struct FiatPriceClient {
    public var getZcashPrice: (NighthawkSetting.FiatCurrency) async throws -> Double?
}

extension FiatPriceClient: DependencyKey {
    struct FiatPriceApiResponse: Codable, Equatable {
        let data: [String: Double]
        
        enum CodingKeys: String, CodingKey {
            case data = "zcash"
        }
    }
    
    public static let liveValue = Self(
        getZcashPrice: { currency in
            guard currency != .off else { return nil }
                
            let simplePriceUrl = URL.coinGeckoApi
                .appending(path: "simple/price")
                .appending(
                    queryItems: [
                        .init(name: "ids", value: "zcash"),
                        .init(name: "vs_currencies", value: currency.rawValue)
                    ]
                )
            
            let (data, _) = try await URLSession.shared.data(from: simplePriceUrl)
            let priceData = try JSONDecoder().decode(FiatPriceApiResponse.self, from: data)
            return priceData.data[currency.rawValue]
        }
    )
}

extension DependencyValues {
    public var fiatPriceClient: FiatPriceClient {
        get { self[FiatPriceClient.self] }
        set { self[FiatPriceClient.self] = newValue }
    }
}
