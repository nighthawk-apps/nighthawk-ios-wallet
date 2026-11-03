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

            let simplePriceUrl = URL.coinGeckoApi
                .appending(path: "simple/price")
                .appending(
                    queryItems: [
                        .init(name: "ids", value: "darkfi"),
                        .init(name: "vs_currencies", value: currency.rawValue)
                    ]
                )

            let (data, _) = try await fiatPriceSession().data(from: simplePriceUrl)
            let priceData = try JSONDecoder().decode(FiatPriceApiResponse.self, from: data)
            return priceData.data[currency.rawValue]
        }
    )
}

/// CoinGecko is clearnet. Follow the same Nym or Tor SOCKS proxy as the wallet,
/// and only dial the network directly when the user chose Direct.
private func fiatPriceSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    let network = UserDefaults.standard.string(forKey: "darkfiWalletPrivacyNetwork")
        ?? NighthawkSetting.PrivacyNetwork.default.rawValue
    switch network {
    case NighthawkSetting.PrivacyNetwork.direct.rawValue:
        break
    case NighthawkSetting.PrivacyNetwork.tor.rawValue:
        let port = Int(UserDefaults.standard.string(forKey: "darkfiTorSocksPort") ?? "") ?? 9050
        config.connectionProxyDictionary = socksProxy(port: port)
    default:
        config.connectionProxyDictionary = socksProxy(
            port: Int(NighthawkSetting.PrivacyNetwork.nymSocksPort)
        )
    }
    return URLSession(configuration: config)
}

private func socksProxy(port: Int) -> [String: Any] {
    [
        "SOCKSEnable": 1,
        "SOCKSProxy": "127.0.0.1",
        "SOCKSPort": port,
    ]
}

extension DependencyValues {
    public var fiatPriceClient: FiatPriceClient {
        get { self[FiatPriceClient.self] }
        set { self[FiatPriceClient.self] = newValue }
    }
}
