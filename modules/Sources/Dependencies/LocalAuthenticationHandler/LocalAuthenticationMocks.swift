//
//  LocalAuthenticationMocks.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 12.11.2022.
//

import LocalAuthentication

extension LocalAuthenticationClient {
    private static let biometryType: () -> LABiometryType = { .none }
    
    public static let mockAuthenticationSucceeded = Self(
        authenticate: { _ in true },
        biometryType: biometryType
    )
    
    public static let mockAuthenticationFailed = Self(
        authenticate: { _ in false },
        biometryType: biometryType
    )
}
