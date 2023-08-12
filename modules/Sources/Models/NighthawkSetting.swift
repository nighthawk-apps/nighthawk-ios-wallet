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
}
