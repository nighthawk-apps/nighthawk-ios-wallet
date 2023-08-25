//
//  UserNotificationCenterTestKey.swift
//  
//
//  Created by Matthew Watt on 8/23/23.
//

import ComposableArchitecture
import UserNotifications
import XCTestDynamicOverlay

extension UserNotificationCenterClient: TestDependencyKey {
    public static let testValue = Self(
        requestAuthorization: XCTUnimplemented("\(Self.self).requestAuthorization"),
        notificationSettings: XCTUnimplemented("\(Self.self).notificationSettings"),
        add: XCTUnimplemented("\(Self.self).add"),
        removeAllPendingNotificationRequests: XCTUnimplemented("\(Self.self).removeAllPendingNotificationRequests")
    )
}

extension UserNotificationCenterClient {
    public static let noOp = Self(
        requestAuthorization: { _ in false },
        notificationSettings: { NotificationSettings() },
        add: { _ in },
        removeAllPendingNotificationRequests: {}
    )
}
