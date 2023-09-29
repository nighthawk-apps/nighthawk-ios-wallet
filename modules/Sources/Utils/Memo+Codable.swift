//
//  Memo+Codable.swift
//
//
//  Created by Two Point on 9/28/23.
//

import ZcashLightClientKit

extension Memo: Codable {
    enum CodingKeys: String, CodingKey {
        case bytes
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .empty:
            try container.encode([UInt8](), forKey: .bytes)
        case let .text(string):
            try container.encode(Array(string.string.utf8), forKey: .bytes)
        case let .future(bytes):
            try container.encode(bytes.bytes, forKey: .bytes)
        case let .arbitrary(bytes):
            try container.encode(bytes, forKey: .bytes)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bytes = try container.decode([UInt8].self, forKey: .bytes)
        self = try .init(bytes: bytes)
    }
}

