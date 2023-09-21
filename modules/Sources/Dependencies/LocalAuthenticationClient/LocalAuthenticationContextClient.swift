//
//  LocalAuthenticationContext.swift
//  
//
//  Created by Matthew Watt on 9/2/23.
//

import Dependencies
import Foundation
import LocalAuthentication

extension DependencyValues {
    public var localAuthenticationContext: LocalAuthenticationContextClientGenerator {
        get { self[LocalAuthenticationContextGeneratorKey.self] }
        set { self[LocalAuthenticationContextGeneratorKey.self] = newValue }
    }
    
    private enum LocalAuthenticationContextGeneratorKey: DependencyKey {
        static let liveValue = LocalAuthenticationContextClientGenerator {
            @Dependency(\.laContext) var laContext
            let context = laContext()
            return LocalAuthenticationContextClient(
                biometryType: { context.biometryType },
                canEvaluatePolicy: { policy in
                    var error: NSError?
                    let result = context.canEvaluatePolicy(policy, error: &error)
                    if let error {
                        throw error
                    }
                    
                    return result
                },
                evaluatePolicy: { policy, reason in
                    try await context.evaluatePolicy(policy, localizedReason: reason)
                }
            )
        }
        
        static let testValue = LocalAuthenticationContextClientGenerator {
            XCTFail(#"Unimplemented: @Dependency(\.localAuthenticationContext)"#)
            return LocalAuthenticationContextClient(
                biometryType: { .none },
                canEvaluatePolicy: { _ in false },
                evaluatePolicy: { _, _ in false }
            )
        }
    }
}

public struct LocalAuthenticationContextClientGenerator: Sendable {
    private var generate: @Sendable () -> LocalAuthenticationContextClient
    
    /// Initializes an LocalAuthenticationContextClient generator that generates an LocalAuthenticationContextClient from a closure.
    ///
    /// - Parameter generate: A closure that returns a new LAContext when called.
    public init(_ generate: @escaping @Sendable () -> LocalAuthenticationContextClient) {
        self.generate = generate
    }
    
    public func callAsFunction() -> LocalAuthenticationContextClient {
        self.generate()
    }
}


public struct LocalAuthenticationContextClient {
    public let biometryType: () -> LABiometryType
    public let canEvaluatePolicy: (LAPolicy) throws -> Bool
    public let evaluatePolicy: (LAPolicy, String) async throws -> Bool
    
    public init(
        biometryType: @escaping () -> LABiometryType,
        canEvaluatePolicy: @escaping (LAPolicy) throws -> Bool,
        evaluatePolicy: @escaping (LAPolicy, String) async throws -> Bool
    ) {
        self.biometryType = biometryType
        self.canEvaluatePolicy = canEvaluatePolicy
        self.evaluatePolicy = evaluatePolicy
    }
}
