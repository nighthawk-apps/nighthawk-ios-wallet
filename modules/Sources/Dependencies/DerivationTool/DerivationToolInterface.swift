//
//  DerivationToolInterface.swift
//  stealth
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture

public typealias NetworkType = String

extension DependencyValues {
    public var derivationTool: DerivationToolClient {
        get { self[DerivationToolClient.self] }
        set { self[DerivationToolClient.self] = newValue }
    }
}

/// DarkFi address validation dependency.
///
/// Spending and viewing keys stay inside the Rust UniFFI wallet (`DarkfiWalletHandle`)
/// and are never derived or exposed in Swift.
public struct DerivationToolClient {
    public var isDarkFiAddress: (String, NetworkType) -> Bool
}
