//
//  LocalAuthenticationContext.swift
//  
//
//  Created by Matthew Watt on 9/2/23.
//

import Dependencies
import LocalAuthentication

extension DependencyValues {
    public var laContext: LAContextGenerator {
        get { self[LAContextGeneratorKey.self] }
        set { self[LAContextGeneratorKey.self] = newValue }
    }
    
    private enum LAContextGeneratorKey: DependencyKey {
        static let liveValue = LAContextGenerator { LAContext() }
        static let testValue = LAContextGenerator {
          XCTFail(#"Unimplemented: @Dependency(\.laContext)"#)
          return LAContext()
        }
    }
}

public struct LAContextGenerator: Sendable {
    private var generate: @Sendable () -> LAContext
    
    /// Initializes an LAContext generator that generates an LAContext from a closure.
    ///
    /// - Parameter generate: A closure that returns a new LAContext when called.
    public init(_ generate: @escaping @Sendable () -> LAContext) {
        self.generate = generate
    }
    
    public func callAsFunction() -> LAContext {
        self.generate()
    }
}
