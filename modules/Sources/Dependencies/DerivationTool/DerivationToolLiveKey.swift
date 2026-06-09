//
//  DerivationToolLiveKey.swift
//  stealth
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture

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
            isUnifiedAddress: { _, _ in
                return true
            },
            isSaplingAddress: { _, _ in
                return true
            },
            isTransparentAddress: { _, _ in
                return true
            },
            isDarkFiAddress: { _, _ in
                return true
            }
        )
    }
}
