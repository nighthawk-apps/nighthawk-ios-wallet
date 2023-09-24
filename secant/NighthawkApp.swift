//
//  NighthawkApp.swift
//  secant
//
//  Created by Matthew Watt on 9/11/23.
//

import App
import ComposableArchitecture
import Dependencies
import Foundation
import Generated
import SDKSynchronizer
import SwiftUI
import ZcashLightClientKit

@main
struct NighthawkApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    initialState: AppReducer.State()
                ) {
                    AppReducer(zcashNetwork: TargetConstants.zcashNetwork)
                },
                tokenName: TargetConstants.tokenName,
                networkType: TargetConstants.zcashNetwork.networkType
            )
            .preferredColorScheme(.dark)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    init() {
        FontFamily.registerAllCustomFonts()
        // set the default behavior for the NSDecimalNumber
        NSDecimalNumber.defaultBehavior = Zatoshi.decimalHandler
    }
}

// TODO: Refactor this
// MARK: Zcash Network global type
/// Whenever the ZcashNetwork is required use this var to determine which is the
/// network type suitable for the present target.

public enum TargetConstants {
    public static var zcashNetwork: ZcashNetwork {
#if SECANT_MAINNET
    return ZcashNetworkBuilder.network(for: .mainnet)
#elseif SECANT_TESTNET
    return ZcashNetworkBuilder.network(for: .testnet)
#else
    fatalError("SECANT_MAINNET or SECANT_TESTNET flags not defined on Swift Compiler custom flags of your build target.")
#endif
    }
    
    public static var tokenName: String {
#if SECANT_MAINNET
    return "ZEC"
#elseif SECANT_TESTNET
    return "TAZ"
#else
    fatalError("SECANT_MAINNET or SECANT_TESTNET flags not defined on Swift Compiler custom flags of your build target.")
#endif
    }
}

extension SDKSynchronizerClient: DependencyKey {
    public static let liveValue: SDKSynchronizerClient = Self.live(network: TargetConstants.zcashNetwork)
}
