//
//  PartnersInterface.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import Foundation
import ComposableArchitecture

extension DependencyValues {
    public var partners: PartnersClient {
        get { self[PartnersClient.self] }
        set { self[PartnersClient.self] = newValue }
    }
}

public struct PartnersClient {
    public var sideshiftURL: () -> URL?
    public var stealthexURL: () -> URL?
}
