//
//  DerivationToolInterface.swift
//  stealth
//
//  Created by Lukáš Korba on 12.11.2022.
//

import ComposableArchitecture

public typealias NetworkType = String

public struct UnifiedSpendingKey: Equatable {
    public let bytes: [UInt8]
    public let account: Int
    public init(bytes: [UInt8], account: Int) {
        self.bytes = bytes
        self.account = account
    }
}

public struct UnifiedFullViewingKey: Equatable {
    public let stringEncoded: String
    public init(stringEncoded: String) {
        self.stringEncoded = stringEncoded
    }
}

extension DependencyValues {
    public var derivationTool: DerivationToolClient {
        get { self[DerivationToolClient.self] }
        set { self[DerivationToolClient.self] = newValue }
    }
}

public struct DerivationToolClient {
    public var deriveSpendingKey: ([UInt8], Int, NetworkType) throws -> UnifiedSpendingKey
    public var deriveUnifiedFullViewingKey: (UnifiedSpendingKey, NetworkType) throws -> UnifiedFullViewingKey
    public var isUnifiedAddress: (String, NetworkType) -> Bool
    public var isSaplingAddress: (String, NetworkType) -> Bool
    public var isTransparentAddress: (String, NetworkType) -> Bool
    public var isDarkFiAddress: (String, NetworkType) -> Bool
}
