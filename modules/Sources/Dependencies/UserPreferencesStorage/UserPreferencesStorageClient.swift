//
//  UserPreferencesStorageInterface.swift
//  stealth
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
    
    // Tor network
    public var torForWalletEnabled: () -> Bool
    public var setTorForWalletEnabled: (Bool) -> Void
    public var torForChatEnabled: () -> Bool
    public var setTorForChatEnabled: (Bool) -> Void
    public var useEmbeddedTor: () -> Bool
    public var setUseEmbeddedTor: (Bool) -> Void
    public var torSocksHost: () -> String?
    public var setTorSocksHost: (String) -> Void
    public var torSocksPort: () -> String?
    public var setTorSocksPort: (String) -> Void

    public var isUserBackupComplete: () -> Bool
    public var setIsUserBackupComplete: (Bool) -> Void

    public var runEmbeddedDarkirc: () -> Bool
    public var setRunEmbeddedDarkirc: (Bool) -> Void
    public var darkircDagsCount: () -> Int
    public var setDarkircDagsCount: (Int) -> Void
    public var darkircFastMode: () -> Bool
    public var setDarkircFastMode: (Bool) -> Void
    public var dmPublicKey: () -> String?
    public var setDmPublicKey: (String?) -> Void
    public var dmSecretKey: () -> String?
    public var setDmSecretKey: (String?) -> Void
    public var encryptedChannelsJSON: () -> String?
    public var setEncryptedChannelsJSON: (String?) -> Void
    public var encryptedContactsJSON: () -> String?
    public var setEncryptedContactsJSON: (String?) -> Void
    
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
        torForWalletEnabled: { UserPreferencesStorage.live.torForWalletEnabled },
        setTorForWalletEnabled: UserPreferencesStorage.live.setTorForWalletEnabled(_:),
        torForChatEnabled: { UserPreferencesStorage.live.torForChatEnabled },
        setTorForChatEnabled: UserPreferencesStorage.live.setTorForChatEnabled(_:),
        useEmbeddedTor: { UserPreferencesStorage.live.useEmbeddedTor },
        setUseEmbeddedTor: UserPreferencesStorage.live.setUseEmbeddedTor(_:),
        torSocksHost: { UserPreferencesStorage.live.torSocksHost },
        setTorSocksHost: UserPreferencesStorage.live.setTorSocksHost(_:),
        torSocksPort: { UserPreferencesStorage.live.torSocksPort },
        setTorSocksPort: UserPreferencesStorage.live.setTorSocksPort(_:),
        isUserBackupComplete: { UserPreferencesStorage.live.isUserBackupComplete },
        setIsUserBackupComplete: UserPreferencesStorage.live.setIsUserBackupComplete(_:),
        runEmbeddedDarkirc: { UserPreferencesStorage.live.runEmbeddedDarkirc },
        setRunEmbeddedDarkirc: UserPreferencesStorage.live.setRunEmbeddedDarkirc(_:),
        darkircDagsCount: { UserPreferencesStorage.live.darkircDagsCount },
        setDarkircDagsCount: UserPreferencesStorage.live.setDarkircDagsCount(_:),
        darkircFastMode: { UserPreferencesStorage.live.darkircFastMode },
        setDarkircFastMode: UserPreferencesStorage.live.setDarkircFastMode(_:),
        dmPublicKey: { UserPreferencesStorage.live.dmPublicKey },
        setDmPublicKey: UserPreferencesStorage.live.setDmPublicKey(_:),
        dmSecretKey: { UserPreferencesStorage.live.dmSecretKey },
        setDmSecretKey: UserPreferencesStorage.live.setDmSecretKey(_:),
        encryptedChannelsJSON: { UserPreferencesStorage.live.encryptedChannelsJSON },
        setEncryptedChannelsJSON: UserPreferencesStorage.live.setEncryptedChannelsJSON(_:),
        encryptedContactsJSON: { UserPreferencesStorage.live.encryptedContactsJSON },
        setEncryptedContactsJSON: UserPreferencesStorage.live.setEncryptedContactsJSON(_:),
        removeAll: UserPreferencesStorage.live.removeAll
    )
}

extension DependencyValues {
    public var userStoredPreferences: UserPreferencesStorageClient {
        get { self[UserPreferencesStorageClient.self] }
        set { self[UserPreferencesStorageClient.self] = newValue }
    }
}
