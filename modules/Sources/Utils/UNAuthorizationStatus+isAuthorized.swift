//
//  UNAuthorizationStatus+isAuthorized.swift
//  
//
//  Created by Matthew Watt on 8/23/23.
//

import UserNotifications

extension UNAuthorizationStatus {
    public var isAuthorized: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }
}
