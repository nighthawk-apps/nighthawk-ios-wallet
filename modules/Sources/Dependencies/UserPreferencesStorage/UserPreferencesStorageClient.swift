//
//  UserPreferencesStorageInterface.swift
//  secant-testnet
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import ComposableArchitecture
import Models

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
    
    public var isUnstoppableDomainsEnabled: () -> Bool
    public var setIsUnstoppableDomainsEnabled: (Bool) -> Void
    
    public var hasShownAutoshielding: () -> Bool
    public var setHasShownAutoshielding: (Bool) -> Void
    
    public var removeAll: () -> Void
}

extension UserPreferencesStorageClient: DependencyKey {
    public static let liveValue = Self(
        currency: { UserPreferencesStorage.live.currency },
        setCurrency: UserPreferencesStorage.live.setCurrency(_:),
        isFiatConverted: { UserPreferencesStorage.live.isFiatConverted },
        setIsFiatConverted: UserPreferencesStorage.live.setIsFiatConverted(_:),
        screenMode: { UserPreferencesStorage.live.screenMode },
        setScreenMode: UserPreferencesStorage.live.setScreenMode(_:),
        syncNotificationFrequency: { UserPreferencesStorage.live.syncNotificationFrequency },
        setSyncNotificationFrequency: UserPreferencesStorage.live.setSyncNotificationFrequency(_:),
        areBiometricsEnabled: { UserPreferencesStorage.live.areBiometricsEnabled },
        setAreBiometricsEnabled: UserPreferencesStorage.live.setAreBiometricsEnabled(_:),
        isFirstSync: { UserPreferencesStorage.live.isFirstSync },
        setIsFirstSync: UserPreferencesStorage.live.setIsFirstSync(_:),
        isUnstoppableDomainsEnabled: { UserPreferencesStorage.live.isUnstoppableDomainsEnabled },
        setIsUnstoppableDomainsEnabled: UserPreferencesStorage.live.setIsUnstoppableDomainsEnabled(_:),
        hasShownAutoshielding: { UserPreferencesStorage.live.hasShownAutoshielding },
        setHasShownAutoshielding: UserPreferencesStorage.live.setHasShownAutoshielding(_:),
        removeAll: UserPreferencesStorage.live.removeAll
    )
}

extension DependencyValues {
    public var userStoredPreferences: UserPreferencesStorageClient {
        get { self[UserPreferencesStorageClient.self] }
        set { self[UserPreferencesStorageClient.self] = newValue }
    }
}
