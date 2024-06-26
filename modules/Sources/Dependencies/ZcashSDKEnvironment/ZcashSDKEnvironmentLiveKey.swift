//
//  ZcashSDKEnvironmentLiveKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import ZcashLightClientKit

extension ZcashSDKEnvironment: DependencyKey {
    public static let liveValue = Self(
        latestCheckpoint: { network in BlockHeight.ofLatestCheckpoint(network: network) },
        defaultEndpoint: {
            LightWalletEndpoint(
                address: Self.ZcashSDKConstants.endpointMainnetDefaultAddress,
                port: Self.ZcashSDKConstants.endpointMainnetDefaultPort,
                secure: true,
                streamingCallTimeoutInMillis: ZcashSDKConstants.streamingCallTimeoutInMillis
            )
        },
        endpoint: { network in
            LightWalletEndpoint(
                address: Self.endpoint(for: network),
                port: Self.port(for: network),
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
