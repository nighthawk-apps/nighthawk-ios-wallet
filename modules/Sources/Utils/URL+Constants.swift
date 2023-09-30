//
//  URL+Constants.swift
//
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import FileManager
import Foundation
import ZcashLightClientKit

extension URL {
    /// The `DatabaseFilesClient` API returns an instance of the URL or throws an error.
    /// In order to use placeholders for the URL we need a URL instance, hence `emptyURL` and force unwrapp.
    public static let empty = URL(string: "http://empty.url")!// swiftlint:disable:this force_unwrapping
    
    public static let source = URL(string: "https://github.com/nighthawk-apps/nighthawk-ios-wallet")!
    
    public static let friends = URL(string: "https://nighthawkwallet.com/credits")!
    
    public static let terms = URL(string: "https://nighthawkwallet.com/termsconditions")!
    
    public static func latestEventsCache(for networkType: NetworkType) -> URL? {
        @Dependency(\.fileManager) var fileManager
        return try? fileManager.url(
            .documentDirectory,
            .userDomainMask,
            nil,
            true
        )
        .appendingPathComponent(
            "\(networkType.chainName)-latest-wallet-events-cache.json",
            isDirectory: false
        )
    }
}
