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
    public var appIcon: () -> NighthawkSetting.AppIcon
    public var setAppIcon: (NighthawkSetting.AppIcon) -> Void
    
    public var theme: () -> NighthawkSetting.Theme
    public var setTheme: (NighthawkSetting.Theme) -> Void
    
    public var fiatCurrency: () -> NighthawkSetting.FiatCurrency
    public var setFiatCurrency: (NighthawkSetting.FiatCurrency) -> Void
    
    public var screenMode: () -> NighthawkSetting.ScreenMode
    public var setScreenMode: (NighthawkSetting.ScreenMode) -> Void
    
    public var syncNotificationFrequency: () -> NighthawkSetting.SyncNotificationFrequency
    public var setSyncNotificationFrequency: (NighthawkSetting.SyncNotificationFrequency) -> Void
    
    public var areBiometricsEnabled: () -> Bool
    public var setAreBiometricsEnabled: (Bool) -> Void
    
    public var isBandit: () -> Bool
    public var setIsBandit: (Bool) -> Void
    
    public var isFirstSync: () -> Bool
    public var setIsFirstSync: (Bool) -> Void
    
    public var isUnstoppableDomainsEnabled: () -> Bool
    public var setIsUnstoppableDomainsEnabled: (Bool) -> Void
    
    public var hasShownAutoshielding: () -> Bool
    public var setHasShownAutoshielding: (Bool) -> Void
    
    public var isUsingCustomLightwalletd: () -> Bool
    public var setIsUsingCustomLightwalletd: (Bool) -> Void
    
    public var customLightwalletdServer: () -> String?
    public var setCustomLightwalletdServer: (String?) -> Void
    
    public var removeAll: () -> Void
}

extension UserPreferencesStorageClient: DependencyKey {
    public static let liveValue = Self(
        appIcon: { UserPreferencesStorage.live.appIcon },
        setAppIcon: UserPreferencesStorage.live.setAppIcon(_:),
        theme: { UserPreferencesStorage.live.theme },
        setTheme: UserPreferencesStorage.live.setTheme(_:),
        fiatCurrency: { UserPreferencesStorage.live.fiatCurrency },
        setFiatCurrency: UserPreferencesStorage.live.setFiatCurrency(_:),
        screenMode: { UserPreferencesStorage.live.screenMode },
        setScreenMode: UserPreferencesStorage.live.setScreenMode(_:),
        syncNotificationFrequency: { UserPreferencesStorage.live.syncNotificationFrequency },
        setSyncNotificationFrequency: UserPreferencesStorage.live.setSyncNotificationFrequency(_:),
        areBiometricsEnabled: { UserPreferencesStorage.live.areBiometricsEnabled },
        setAreBiometricsEnabled: UserPreferencesStorage.live.setAreBiometricsEnabled(_:),
        isBandit: { UserPreferencesStorage.live.isBandit },
        setIsBandit: UserPreferencesStorage.live.setIsBandit(_:),
        isFirstSync: { UserPreferencesStorage.live.isFirstSync },
        setIsFirstSync: UserPreferencesStorage.live.setIsFirstSync(_:),
        isUnstoppableDomainsEnabled: { UserPreferencesStorage.live.isUnstoppableDomainsEnabled },
        setIsUnstoppableDomainsEnabled: UserPreferencesStorage.live.setIsUnstoppableDomainsEnabled(_:),
        hasShownAutoshielding: { UserPreferencesStorage.live.hasShownAutoshielding },
        setHasShownAutoshielding: UserPreferencesStorage.live.setHasShownAutoshielding(_:),
        isUsingCustomLightwalletd: { UserPreferencesStorage.live.isUsingCustomLightwalletd },
        setIsUsingCustomLightwalletd: UserPreferencesStorage.live.setIsUsingCustomLightwalletd(_:),
        customLightwalletdServer: { UserPreferencesStorage.live.customLightwalletdServer },
        setCustomLightwalletdServer: UserPreferencesStorage.live.setCustomLightwalletdServer(_:),
        removeAll: UserPreferencesStorage.live.removeAll
    )
}

extension DependencyValues {
    public var userStoredPreferences: UserPreferencesStorageClient {
        get { self[UserPreferencesStorageClient.self] }
        set { self[UserPreferencesStorageClient.self] = newValue }
    }
}
