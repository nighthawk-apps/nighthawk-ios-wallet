//
//  NighthawkConfiguration.swift
//  NighthawkWallet
//
//  Created by Two Point on 1/26/23.
//

import Foundation
import ZcashLightClientKit

@MainActor
enum NighthawkConfiguration {
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()
}

// MARK: - Build configuration variables
extension NighthawkConfiguration {
    static let appBuild: String = {
        guard let buildString = NighthawkConfiguration.infoDictionary["APP_BUILD"] as? String else {
            fatalError("APP_BUILD not set in plist for this configuration")
        }
        
        return buildString
    }()
    
    static let appBundleId: String = {
        guard let bundleIdString = NighthawkConfiguration.infoDictionary["APP_BUNDLE_ID"] as? String else {
            fatalError("APP_BUILD not set in plist for this configuration")
        }
        
        return bundleIdString
    }()
    
    static let appName: String = {
        guard let appNameString = NighthawkConfiguration.infoDictionary["APP_NAME"] as? String else {
            fatalError("APP_NAME not set in plist for this environment")
        }
        
        return appNameString
    }()
    
    static let appNetwork: String = {
        guard let appNetworkString = NighthawkConfiguration.infoDictionary["APP_NETWORK"] as? String else {
            fatalError("APP_NETWORK not set in plist for this configuration")
        }
        
        return appNetworkString
    }()
    
    static let appVersion: String = {
        guard let appVersionString = NighthawkConfiguration.infoDictionary["APP_VERSION"] as? String else {
            fatalError("APP_VERSION not set in plist for this configuration")
        }
        
        return appVersionString
    }()
}

// MARK: - Configuration + ZcashLightClientKit
extension NighthawkConfiguration {
    static let networkType: NetworkType = {
        if Self.appNetwork == "mainnet" {
            return .mainnet
        }
        
        return .testnet
    }()
    
    static let lightwalletEndpoint: String = {
        switch Self.networkType {
        case .testnet: return "testnet.lightwalletd.com"
        case .mainnet: return "mainnet.lightwalletd.com"
        }
    }()
}
