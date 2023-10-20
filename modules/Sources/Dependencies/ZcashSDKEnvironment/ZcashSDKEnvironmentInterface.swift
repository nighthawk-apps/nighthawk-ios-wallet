//
//  ZcashSDKEnvironmentInterface.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import UserPreferencesStorage
import ZcashLightClientKit

extension DependencyValues {
    public var zcashSDKEnvironment: ZcashSDKEnvironment {
        get { self[ZcashSDKEnvironment.self] }
        set { self[ZcashSDKEnvironment.self] = newValue }
    }
}

extension ZcashSDKEnvironment {
    public enum ZcashSDKConstants {
        static let endpointTestnetAddress = "testnet.lightwalletd.com"
        static let endpointTestnetPort = 9067
        static let mnemonicWordsMaxCount = 24
        static let requiredTransactionConfirmations = 10
        static let streamingCallTimeoutInMillis = Int64(10 * 60 * 60 * 1000) // ten hours
        static let banditAmount = Zatoshi(11_700_000)
    }

    public static func endpoint(for network: ZcashNetwork) -> String {
        @Dependency(\.userStoredPreferences) var userStoredPreferences
        
        return switch network.networkType {
        case .testnet:
            ZcashSDKConstants.endpointTestnetAddress
        case .mainnet:
            userStoredPreferences.lightwalletdServer().host
        }
    }
    
    public static func port(for network: ZcashNetwork) -> Int {
        @Dependency(\.userStoredPreferences) var userStoredPreferences
        
        return switch network.networkType {
        case .testnet:
            ZcashSDKConstants.endpointTestnetPort
        case .mainnet:
            userStoredPreferences.lightwalletdServer().port
        }
    }
    
    public static func banditAddress(for network: ZcashNetwork) -> String {
            return switch network.networkType {
            case .testnet:
                "ztestsapling1suwzseeq4sl0lpjssd67d7epwng6gn2y4ppnhnuqqp54mew55n7t89dtncqtxt88psrqq55h2hd"
            case .mainnet:
                "zs1nhawkewaslscuey9qhnv9e4wpx77sp73kfu0l8wh9vhna7puazvfnutyq5ymg830hn5u2dmr0sf"
            }
        }
}

public struct ZcashSDKEnvironment {
    public var latestCheckpoint: (ZcashNetwork) -> BlockHeight //{ BlockHeight.ofLatestCheckpoint(network: network()) }
    public let endpoint: (ZcashNetwork) -> LightWalletEndpoint
    public let banditAddress: (ZcashNetwork) -> String
    public let banditAmount: Zatoshi
    public let memoCharLimit: Int
    public let mnemonicWordsMaxCount: Int
    public let requiredTransactionConfirmations: Int
    public let sdkVersion: String
}
