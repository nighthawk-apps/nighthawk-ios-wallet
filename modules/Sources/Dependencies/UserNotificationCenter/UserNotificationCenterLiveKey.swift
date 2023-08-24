//
//  UserNotificationCenterLiveKey.swift
//  
//
//  Created by Matthew Watt on 8/23/23.
//

import ComposableArchitecture
import Foundation
import UserNotifications

extension UserNotificationCenterClient: DependencyKey {
    public static let liveValue = UserNotificationCenterClient.live()
    
    public static func live(
        userNotificationCenter: UNUserNotificationCenter = .current()
    ) -> Self {
        Self(
            requestAuthorization: { try await userNotificationCenter.requestAuthorization(options: $0) },
            notificationSettings: {
                let settings = await userNotificationCenter.notificationSettings()
                return NotificationSettings(rawValue: settings)
            },
            add: { try await userNotificationCenter.add($0) },
            removeAllPendingNotificationRequests: { userNotificationCenter.removeAllPendingNotificationRequests() }
        )
    }
}
