//
//  UserNotificationCenterInterface.swift
//  
//
//  Created by Matthew Watt on 8/23/23.
//

import ComposableArchitecture
import Foundation
import UserNotifications

extension DependencyValues {
    public var userNotificationCenter: UserNotificationCenterClient {
        get { self[UserNotificationCenterClient.self] }
        set { self[UserNotificationCenterClient.self] = newValue }
    }
}

public struct UserNotificationCenterClient {
    public let requestAuthorization: (UNAuthorizationOptions) async throws -> Bool
    public let notificationSettings: () async -> NotificationSettings
    public let add: (UNNotificationRequest) async throws -> Void
    public let removeAllPendingNotificationRequests: () -> Void
    
    public init(
        requestAuthorization: @escaping (UNAuthorizationOptions) async throws -> Bool,
        notificationSettings: @escaping () async -> NotificationSettings,
        add: @escaping (UNNotificationRequest) async throws -> Void,
        removeAllPendingNotificationRequests: @escaping () -> Void
    ) {
        self.requestAuthorization = requestAuthorization
        self.notificationSettings = notificationSettings
        self.add = add
        self.removeAllPendingNotificationRequests = removeAllPendingNotificationRequests
    }
}
