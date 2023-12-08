//
//  ZcashSDKEnvironmentTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import ZcashLightClientKit
import XCTestDynamicOverlay

extension ZcashSDKEnvironment: TestDependencyKey {
    public static let testnet = ZcashSDKEnvironment.liveValue

    public static let testValue = Self(
        latestCheckpoint: { _ in 0 },
        endpoint: { _ in
            LightWalletEndpoint(
                address: ZcashSDKConstants.endpointTestnetAddress,
                port: ZcashSDKConstants.endpointTestnetPort,
                secure: true,
                streamingCallTimeoutInMillis: ZcashSDKConstants.streamingCallTimeoutInMillis
            )
        },
        banditAddress: { Self.banditAddress(for: $0) },
        banditAmount: ZcashSDKConstants.banditAmount, 
        replyToPrefix: ZcashSDKConstants.replyToPrefix,
        memoCharLimit: MemoBytes.capacity,
        mnemonicWordsMaxCount: ZcashSDKConstants.mnemonicWordsMaxCount,
        requiredTransactionConfirmations: ZcashSDKConstants.requiredTransactionConfirmations,
        sdkVersion: "2.0.3"
    )
}
