//
//  UNSClient.swift
//
//
//  Created by Matthew Watt on 9/28/23.
//

import Dependencies
import Foundation
import UnstoppableDomainsResolution

public struct UNSClient {
    public var resolveUNSAddress: (String) async throws -> String?
}

extension UNSClient: DependencyKey {
    public static let liveValue = UNSClient(
        resolveUNSAddress: { address in
            let supportedTLD = await getSupportedTLD()
            let isValidUNS = supportedTLD.first(where: { address.contains($0) }) != nil || supportedTLD.isEmpty
            if isValidUNS {
                let resolution = try Resolution()
                return try await withCheckedThrowingContinuation { continuation in
                    resolution.addr(domain: address, ticker: "ZEC") { result in
                        switch result {
                        case let .success(resolved):
                            continuation.resume(returning: resolved)
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            
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

// MARK: - Implementation
private func getSupportedTLD() async -> [String] {
    struct TLD: Decodable {
        let tlds: [String]
    }
    
    let url = URL(string: "https://resolve.unstoppabledomains.com/supported_tlds")!
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let tld = try JSONDecoder().decode(TLD.self, from: data)
        return tld.tlds
    } catch {
        return []
    }
}
