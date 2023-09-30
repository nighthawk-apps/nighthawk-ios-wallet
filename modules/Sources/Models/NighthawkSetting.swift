//
//  NighthawkSetting.swift
//  
//
//  Created by Matthew Watt on 8/3/23.
//

import Foundation

public enum NighthawkSetting {
    public enum ScreenMode: String, CaseIterable, Identifiable, Hashable {
        case keepOn
        case off
        
        public var id: String { rawValue }
    }
    
    public enum SyncNotificationFrequency: String, CaseIterable, Identifiable, Hashable {
        case weekly
        case monthly
        case off
        
        public var id: String { rawValue }
    }
    
    public enum FiatCurrency: String, CaseIterable, Identifiable, Hashable {
        case usd
        case eur
        case inr
        case jpy
        case gbp
        case cad
        case aud
        case hkd
        case sgd
        case chf
        case cny
        case krw
        case off
        
        public var id: String { rawValue }
    }
}
