//
//  LocalAuthenticationLiveKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture
import LocalAuthentication
import Generated

extension LocalAuthenticationClient: DependencyKey {
    public static let liveValue = LocalAuthenticationClient.live()
    
    public static func live(
        context: LAContext = .init()
    ) -> Self {
        // context.biometryType is not populated on the context until this method is called
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        return Self(
            authenticate: { reason in
                var error: NSError?
                
                do {
                    /// Biometrics validation
                    if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                    } else {
                        /// No local authentication available, user's device is not protected, fallback to allow access to sensitive content
                        return true
                    }
                } catch {
                    /// Some interruption occurred during the authentication, access to the sensitive content is therefore forbidden
                    return false
                }
            },
            biometryType: { context.biometryType }
        )
    }
}
