//
//  UNSClient.swift
//
//
//  Created by Matthew Watt on 9/28/23.
//

import Dependencies
import Foundation

public struct UNSClient {
    public var resolveUNSAddress: (String) async throws -> String?
}

extension UNSClient: DependencyKey {
    public static let liveValue = UNSClient(
        resolveUNSAddress: { _ in
            // Darkfi does not use Unstoppable Domains.
            return nil
        }
    )
}

extension DependencyValues {
    public var unsClient: UNSClient {
        get { self[UNSClient.self] }
        set { self[UNSClient.self] = newValue }
    }
}
