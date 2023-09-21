//
//  NotificationSettings.swift
//  
//
//  Created by Matthew Watt on 8/23/23.
//

import UserNotifications

public struct NotificationSettings: Equatable, Hashable {
    public let rawValue: UNNotificationSettings?
    
    public var authorizationStatus: UNAuthorizationStatus
    public var soundSetting: UNNotificationSetting
    public var badgeSetting: UNNotificationSetting
    public var alertSetting: UNNotificationSetting
    public var notificationCenterSetting: UNNotificationSetting
    public var lockScreenSetting: UNNotificationSetting
    public var carPlaySetting: UNNotificationSetting
    public var alertStyle: UNAlertStyle
    public var showPreviewsSetting: UNShowPreviewsSetting
    public var criticalAlertSetting: UNNotificationSetting
    public var providesAppNotificationSettings: Bool
    public var announcementSetting: UNNotificationSetting
    public var timeSensitiveSetting: UNNotificationSetting
    public var scheduledDeliverySetting: UNNotificationSetting
    public var directMessagesSetting: UNNotificationSetting
    
    public init(rawValue: UNNotificationSettings) {
        self.rawValue = rawValue
        self.authorizationStatus = rawValue.authorizationStatus
        self.soundSetting = rawValue.soundSetting
        self.badgeSetting = rawValue.badgeSetting
        self.alertSetting = rawValue.alertSetting
        self.notificationCenterSetting = rawValue.notificationCenterSetting
        self.lockScreenSetting = rawValue.lockScreenSetting
        self.carPlaySetting = rawValue.carPlaySetting
        self.alertStyle = rawValue.alertStyle
        self.showPreviewsSetting = rawValue.showPreviewsSetting
        self.criticalAlertSetting = rawValue.criticalAlertSetting
        self.providesAppNotificationSettings = rawValue.providesAppNotificationSettings
        self.announcementSetting = rawValue.announcementSetting
        self.timeSensitiveSetting = rawValue.timeSensitiveSetting
        self.scheduledDeliverySetting = rawValue.scheduledDeliverySetting
        self.directMessagesSetting = rawValue.directMessagesSetting
    }
    
    public init(
        authorizationStatus: UNAuthorizationStatus = .notDetermined,
        soundSetting: UNNotificationSetting = .disabled,
        badgeSetting: UNNotificationSetting = .disabled,
        alertSetting: UNNotificationSetting = .disabled,
        notificationCenterSetting: UNNotificationSetting = .disabled,
        lockScreenSetting: UNNotificationSetting = .disabled,
        carPlaySetting: UNNotificationSetting = .disabled,
        alertStyle: UNAlertStyle = .none,
        showPreviewsSetting: UNShowPreviewsSetting = .never,
        criticalAlertSetting: UNNotificationSetting = .disabled,
        providesAppNotificationSettings: Bool = false,
        announcementSetting: UNNotificationSetting = .disabled,
        timeSensitiveSetting: UNNotificationSetting = .disabled,
        scheduledDeliverySetting: UNNotificationSetting = .disabled,
        directMessagesSetting: UNNotificationSetting = .disabled
    ) {
        self.rawValue = nil
        
        self.authorizationStatus = authorizationStatus
        self.soundSetting = soundSetting
        self.badgeSetting = badgeSetting
        self.alertSetting = alertSetting
        self.notificationCenterSetting = notificationCenterSetting
        self.lockScreenSetting = lockScreenSetting
        self.carPlaySetting = carPlaySetting
        self.alertStyle = alertStyle
        self.showPreviewsSetting = showPreviewsSetting
        self.criticalAlertSetting = criticalAlertSetting
        self.providesAppNotificationSettings = providesAppNotificationSettings
        self.announcementSetting = announcementSetting
        self.timeSensitiveSetting = timeSensitiveSetting
        self.scheduledDeliverySetting = scheduledDeliverySetting
        self.directMessagesSetting = directMessagesSetting
    }
}
