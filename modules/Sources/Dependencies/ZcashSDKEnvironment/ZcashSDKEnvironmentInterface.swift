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
    }

    public static func endpoint(for network: ZcashNetwork) -> String {
        @Dependency(\.userStoredPreferences) var userStoredPreferences
        
        switch network.networkType {
        case .testnet:
            return ZcashSDKConstants.endpointTestnetAddress
        case .mainnet:
            return userStoredPreferences.lightwalletdServer().host
        }
    }
    
    public static func port(for network: ZcashNetwork) -> Int {
        @Dependency(\.userStoredPreferences) var userStoredPreferences
        
        return switch network.networkType {
        case .testnet:
            9067
        case .mainnet:
            userStoredPreferences.lightwalletdServer().port
        }
    }
    
    public static func banditAddress(for network: ZcashNetwork) -> String {
        return switch network.networkType {
        case .testnet:
            ""
        case .mainnet:
            // TODO: This will obviously change
            "t1YkabPwXoCDFLW5yaxyG2kiikxCRg5UV2X"
        }
    }
}

public struct ZcashSDKEnvironment {
    public var latestCheckpoint: (ZcashNetwork) -> BlockHeight //{ BlockHeight.ofLatestCheckpoint(network: network()) }
    public let endpoint: (ZcashNetwork) -> LightWalletEndpoint
    public let banditAddress: (ZcashNetwork) -> String
    public let memoCharLimit: Int
    public let mnemonicWordsMaxCount: Int
    public let requiredTransactionConfirmations: Int
    public let sdkVersion: String
}
