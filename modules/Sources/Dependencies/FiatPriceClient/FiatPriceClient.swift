//
//  FiatPriceClient.swift
//

import ComposableArchitecture
import Foundation
import Models
import Utils

public struct FiatPriceClient {
    public var getDrkPrice: (NighthawkSetting.FiatCurrency) async throws -> Double?
}

extension FiatPriceClient: DependencyKey {
    struct FiatPriceApiResponse: Codable, Equatable {
        let data: [String: Double]

        enum CodingKeys: String, CodingKey {
            case data = "darkfi"
        }
    }

    public static let liveValue = Self(
        getDrkPrice: { currency in
            guard currency != .off else { return nil }
            let defaults = UserDefaults.standard
            let torOn = (defaults.object(forKey: "darkfiTorForWallet") as? Bool) ?? true
            guard torOn else { return nil }
            let host = (defaults.string(forKey: "darkfiTorSocksHost")?.trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0.isEmpty ? nil : $0 } ?? "127.0.0.1"
            let port = UInt16(defaults.string(forKey: "darkfiTorSocksPort") ?? "9050") ?? 9050
            let config = URLSessionConfiguration.ephemeral
            config.connectionProxyDictionary = [
                "SOCKSEnable": NSNumber(value: 1),
                "SOCKSProxy": host,
                "SOCKSPort": NSNumber(value: Int(port))
            ]
            let session = URLSession(configuration: config)

            let simplePriceUrl = URL.coinGeckoApi
                .appending(path: "simple/price")
                .appending(
                    queryItems: [
                        .init(name: "ids", value: "darkfi"),
                        .init(name: "vs_currencies", value: currency.rawValue)
                    ]
                )

            let (data, _) = try await session.data(from: simplePriceUrl)
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
