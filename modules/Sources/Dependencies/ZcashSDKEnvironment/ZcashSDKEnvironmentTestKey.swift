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
    public static let testnet = ZcashSDKEnvironment.live(network: ZcashNetworkBuilder.network(for: .testnet))

    public static let testValue = Self(
        latestCheckpoint: 0,
        defaultEndpoint: LightWalletEndpoint(
            address: ZcashSDKConstants.endpointTestnetAddress,
            port: ZcashSDKConstants.endpointTestnetPort,
            secure: true,
            streamingCallTimeoutInMillis: ZcashSDKConstants.streamingCallTimeoutInMillis
        ),
        endpoint: LightWalletEndpoint(
            address: ZcashSDKConstants.endpointTestnetAddress,
            port: ZcashSDKConstants.endpointTestnetPort,
            secure: true,
            streamingCallTimeoutInMillis: ZcashSDKConstants.streamingCallTimeoutInMillis
        ),
        banditAddress: Self.banditAddress(for: ZcashNetworkBuilder.network(for: .testnet)),
        banditAmount: ZcashSDKConstants.banditAmount,
        replyToPrefix: ZcashSDKConstants.replyToPrefix,
        memoCharLimit: MemoBytes.capacity,
        mnemonicWordsMaxCount: ZcashSDKConstants.mnemonicWordsMaxCount,
        network: ZcashNetworkBuilder.network(for: .testnet),
        requiredTransactionConfirmations: ZcashSDKConstants.requiredTransactionConfirmations,
        sdkVersion: "2.1.12",
        tokenName: "TAZ"
    )
}
