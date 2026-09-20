//
//  DerivationToolLiveKey.swift
//  stealth
//

import ComposableArchitecture
import Utils

extension DerivationToolClient: DependencyKey {
    public static let liveValue = DerivationToolClient.live()

    public static func live() -> Self {
        Self(
            deriveSpendingKey: { _, accountIndex, _ in
                return UnifiedSpendingKey(
                    bytes: [],
                    account: accountIndex
                )
            },
            deriveUnifiedFullViewingKey: { _, _ in
                return UnifiedFullViewingKey(
                    stringEncoded: ""
                )
            },
            isUnifiedAddress: { address, network in
                DarkfiAddressFormat.isValid(address, network: network)
            },
            isSaplingAddress: { _, _ in
                false
            },
            isTransparentAddress: { _, _ in
                false
            },
            isDarkFiAddress: { address, network in
                DarkfiAddressFormat.isValid(address, network: network)
            }
        )
    }
}
