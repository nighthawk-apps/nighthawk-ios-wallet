//
//  FiatPriceClient.swift
//
//
//  Created by Matthew Watt on 10/1/23.
//

import ComposableArchitecture
import DarkfiCore
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

            let (data, _) = try await FiatSessionManager.shared.session().data(from: simplePriceUrl)
            let priceData = try JSONDecoder().decode(FiatPriceApiResponse.self, from: data)
            return priceData.data[currency.rawValue]
        }
    )
}

private struct FiatProxyConfig: Equatable {
    let port: Int?
    let username: String?
    let password: String?

    static func current() -> FiatProxyConfig {
        let stored = NighthawkSetting.PrivacyNetwork(
            rawValue: UserDefaults.standard.string(forKey: "darkfiWalletPrivacyNetwork")
                ?? NighthawkSetting.PrivacyNetwork.default.rawValue
        ) ?? .default
        let disableDirect = UserDefaults.standard.bool(forKey: "darkfiDisableDirectConnection")
        let resolvedRaw = SessionPrivacyOverride.resolved(stored: stored)
        let resolved: NighthawkSetting.PrivacyNetwork =
            (disableDirect && resolvedRaw == .direct) ? .nym : resolvedRaw
        let port: Int?
        switch resolved {
        case .direct:
            port = nil
        case .tor:
            port = Int(UserDefaults.standard.string(forKey: "darkfiTorSocksPort") ?? "") ?? 9050
        case .nym:
            port = Int(NighthawkSetting.PrivacyNetwork.nymSocksPort)
        }
        guard let port else {
            return FiatProxyConfig(port: nil, username: nil, password: nil)
        }
        let creds = socksAuthCredentials()
        return FiatProxyConfig(port: port, username: creds?.username, password: creds?.password)
    }

    private static func socksAuthCredentials() -> (username: String, password: String)? {
        let raw = transportSocksAuthJson()
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let user = json["username"], !user.isEmpty,
              let pass = json["password"], !pass.isEmpty else {
            return nil
        }
        return (user, pass)
    }
}

private final class FiatSocksAuthDelegate: NSObject, URLSessionTaskDelegate {
    let username: String?
    let password: String?

    init(username: String?, password: String?) {
        self.username = username
        self.password = password
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.isProxy(),
           let username, let password {
            completionHandler(.useCredential, URLCredential(user: username, password: password, persistence: .forSession))
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

/// CoinGecko is clearnet. Follow the same Nym or Tor SOCKS proxy as the wallet,
/// reusing a managed `URLSession` keyed by proxy config and invalidating on change.
private final class FiatSessionManager {
    static let shared = FiatSessionManager()

    private let lock = NSLock()
    private var cachedConfig: FiatProxyConfig?
    private var cachedSession: URLSession?
    private var cachedAuthHandler: FiatSocksAuthDelegate?

    func session() -> URLSession {
        let desired = FiatProxyConfig.current()
        lock.lock()
        defer { lock.unlock() }
        if cachedConfig == desired, let cachedSession {
            return cachedSession
        }
        cachedSession?.invalidateAndCancel()
        let config = URLSessionConfiguration.ephemeral
        var delegate: FiatSocksAuthDelegate?
        if let port = desired.port {
            var proxy: [String: Any] = [
                "SOCKSEnable": 1,
                "SOCKSProxy": "127.0.0.1",
                "SOCKSPort": port
            ]
            if let user = desired.username, let pass = desired.password {
                proxy["SOCKSUser"] = user
                proxy["SOCKSPass"] = pass
                delegate = FiatSocksAuthDelegate(username: user, password: pass)
            }
            config.connectionProxyDictionary = proxy
        }
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        cachedConfig = desired
        cachedSession = session
        cachedAuthHandler = delegate
        return session
    }
}

extension DependencyValues {
    public var fiatPriceClient: FiatPriceClient {
        get { self[FiatPriceClient.self] }
        set { self[FiatPriceClient.self] = newValue }
    }
}
