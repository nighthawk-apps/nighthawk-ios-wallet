//
//  UserPreferencesStorageInterface.swift
//  secant-testnet
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import ComposableArchitecture
import Models

extension DependencyValues {
    public var userStoredPreferences: UserPreferencesStorageClient {
        get { self[UserPreferencesStorageClient.self] }
        set { self[UserPreferencesStorageClient.self] = newValue }
    }
}

public struct UserPreferencesStorageClient {
    public var currency: () -> String
    public var setCurrency: (String) -> Void

    public var isFiatConverted: () -> Bool
    public var setIsFiatConverted: (Bool) -> Void
    
    public var screenMode: () -> NighthawkSetting.ScreenMode
    public var setScreenMode: (NighthawkSetting.ScreenMode) -> Void
    
    public var syncNotificationFrequency: () -> NighthawkSetting.SyncNotificationFrequency
    public var setSyncNotificationFrequency: (NighthawkSetting.SyncNotificationFrequency) -> Void
    
    public var areBiometricsEnabled: () -> Bool
    public var setAreBiometricsEnabled: (Bool) -> Void
    
    public var isFirstSync: () -> Bool
    public var setIsFirstSync: (Bool) -> Void

    public var removeAll: () -> Void
}
