//
//  PartnersLiveKey.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import Foundation
import ComposableArchitecture

extension PartnersClient: DependencyKey {
    public static let liveValue = Self(
        stealthexURL: { URL(string: "https://stealthex.io/?ref=x80l5bu8wq") }
    )
}
