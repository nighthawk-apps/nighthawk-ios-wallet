//
//  ZcashSDKEnvironmentLiveKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import ZcashLightClientKit

extension ZcashSDKEnvironment {
    public static func live(network: ZcashNetwork) -> Self {
        Self(
            latestCheckpoint: BlockHeight.ofLatestCheckpoint(network: network),
            defaultEndpoint: LightWalletEndpoint(
                address: Self.ZcashSDKConstants.endpointMainnetDefaultAddress,
                port: Self.ZcashSDKConstants.endpointMainnetDefaultPort,
                secure: true,
                streamingCallTimeoutInMillis: ZcashSDKConstants.streamingCallTimeoutInMillis
            ),
            endpoint: LightWalletEndpoint(
                address: Self.endpoint(for: network),
                port: Self.port(for: network),
                secure: true,
                streamingCallTimeoutInMillis: ZcashSDKConstants.streamingCallTimeoutInMillis
            ),
            banditAddress: Self.banditAddress(for: network),
            banditAmount: ZcashSDKConstants.banditAmount,
            replyToPrefix: ZcashSDKConstants.replyToPrefix,
            memoCharLimit: MemoBytes.capacity,
            mnemonicWordsMaxCount: ZcashSDKConstants.mnemonicWordsMaxCount,
            network: network,
            requiredTransactionConfirmations: ZcashSDKConstants.requiredTransactionConfirmations,
            sdkVersion: "2.1.12",
            tokenName: network.networkType == .testnet ? "TAZ" : "ZEC"
        )
    }
}
