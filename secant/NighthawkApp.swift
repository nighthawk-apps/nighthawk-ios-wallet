//
//  NighthawkApp.swift
//  secant
//
//  Created by Matthew Watt on 9/11/23.
//

import App
import ComposableArchitecture
import Foundation
import Generated
import SDKSynchronizer
import SwiftUI
import ZcashLightClientKit
import ZcashSDKEnvironment

@main
struct NighthawkApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    initialState: AppReducer.State()
                ) {
                    AppReducer()
                }
            )            
        }
    }
    
    init() {
        FontFamily.registerAllCustomFonts()
        // set the default behavior for the NSDecimalNumber
        NSDecimalNumber.defaultBehavior = Zatoshi.decimalHandler
    }
}

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
}

extension ZcashSDKEnvironment: DependencyKey {
    public static let liveValue: ZcashSDKEnvironment = Self.live(network: TargetConstants.zcashNetwork)
}
