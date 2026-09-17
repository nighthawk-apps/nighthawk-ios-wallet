//
//  UNAuthorizationStatus+isAuthorized.swift
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
