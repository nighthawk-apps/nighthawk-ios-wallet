//
//  UserNotificationCenterTestKey.swift
//

import ComposableArchitecture
import UserNotifications
import XCTestDynamicOverlay

extension UserNotificationCenterClient: TestDependencyKey {
    public static let testValue = Self(
        requestAuthorization: unimplemented("\(Self.self).requestAuthorization", placeholder: true),
        notificationSettings: unimplemented("\(Self.self).notificationSettings", placeholder: .init()),
        add: unimplemented("\(Self.self).add"),
        removeAllPendingNotificationRequests: unimplemented("\(Self.self).removeAllPendingNotificationRequests")
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
