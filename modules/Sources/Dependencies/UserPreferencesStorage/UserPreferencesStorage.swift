//
//  UserPreferencesStorage.swift
//  stealth
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import Models
import UserDefaults
import WalletStorage

/// Live implementation of the `UserPreferences` using User Defaults
/// according to https://developer.apple.com/documentation/foundation/userdefaults
/// the UserDefaults class is thread-safe.
public struct UserPreferencesStorage {
    public enum Constants: String, CaseIterable {
        case darkfiAppIcon
        case darkfiTheme
        case darkfiFiatCurrency
        case darkfiScreenMode
        case darkfiSyncNotificationFrequency
        case darkfiBiometricsEnabled
        case darkfiIsBandit
        case darkfiIsFirstSync
        case darkfiIsUnstoppableDomainsEnabled
        case darkfiHasShownAutoshielding
        case darkfiUseCustomLightwalletd
        case darkfiCustomLightwalletdServer
        case darkfiTorForWallet
        case darkfiTorForChat
        case darkfiUseEmbeddedTor
        case darkfiTorSocksHost
        case darkfiTorSocksPort
        case darkfiIsUserBackupComplete
        case darkfiRunEmbeddedDarkirc
        case darkfiDarkircDagsCount
        case darkfiDarkircFastMode
        // DM keys and encrypted channel/contact JSON are now stored
        // in the Keychain via ChatSecureStorage (not in UserDefaults).
    }
    
    /// Default values for all preferences in case there is no value stored (counterparts to `Constants`)
    private let icon: NighthawkSetting.AppIcon
    private let defaultTheme: NighthawkSetting.Theme
    private let currency: NighthawkSetting.FiatCurrency
    private let selectedScreenMode: NighthawkSetting.ScreenMode
    private let selectedSyncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency
    private let biometricsEnabled: Bool
    private let bandit: Bool
    private let firstSync: Bool
    private let unstoppableDomainsEnabled: Bool
    private let shownAutoshielding: Bool
    private let useCustomLightwalletd: Bool
    private let selectedCustomLightwalletdServer: String?
    
    private let userDefaults: UserDefaultsClient
    private let chatSecure = ChatSecureStorage()
    
    public init(
        icon: NighthawkSetting.AppIcon,
        defaultTheme: NighthawkSetting.Theme,
        currency: NighthawkSetting.FiatCurrency,
        selectedScreenMode: NighthawkSetting.ScreenMode,
        selectedSyncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency,
        biometricsEnabled: Bool,
        bandit: Bool,
        firstSync: Bool,
        unstoppableDomainsEnabled: Bool,
        shownAutoshielding: Bool,
        useCustomLightwalletd: Bool,
        selectedCustomLightwalletdServer: String?,
        userDefaults: UserDefaultsClient
    ) {
        self.icon = icon
        self.defaultTheme = defaultTheme
        self.currency = currency
        self.selectedScreenMode = selectedScreenMode
        self.selectedSyncNotificationFrequency = selectedSyncNotificationFrequency
        self.biometricsEnabled = biometricsEnabled
        self.bandit = bandit
        self.firstSync = firstSync
        self.unstoppableDomainsEnabled = unstoppableDomainsEnabled
        self.shownAutoshielding = shownAutoshielding
        self.useCustomLightwalletd = useCustomLightwalletd
        self.selectedCustomLightwalletdServer = selectedCustomLightwalletdServer
        self.userDefaults = userDefaults
    }
    
    public var appIcon: NighthawkSetting.AppIcon {
        let rawValue = getValue(forKey: Constants.darkfiAppIcon.rawValue, default: icon.rawValue)
        return NighthawkSetting.AppIcon(rawValue: rawValue) ?? .default
    }
    
    public func setAppIcon(_ icon: NighthawkSetting.AppIcon) {
        setValue(icon.rawValue, forKey: Constants.darkfiAppIcon.rawValue)
    }
    
    public var theme: NighthawkSetting.Theme {
        let rawValue = getValue(forKey: Constants.darkfiTheme.rawValue, default: defaultTheme.rawValue)
        return NighthawkSetting.Theme(rawValue: rawValue) ?? .default
    }
    
    public func setTheme(_ theme: NighthawkSetting.Theme) {
        setValue(theme.rawValue, forKey: Constants.darkfiTheme.rawValue)
    }

    public var fiatCurrency: NighthawkSetting.FiatCurrency {
        let rawValue = getValue(forKey: Constants.darkfiFiatCurrency.rawValue, default: currency.rawValue)
        return NighthawkSetting.FiatCurrency(rawValue: rawValue) ?? .off
    }
    
    public func setFiatCurrency(_ currency: NighthawkSetting.FiatCurrency) {
        setValue(currency.rawValue, forKey: Constants.darkfiFiatCurrency.rawValue)
    }

    public var screenMode: NighthawkSetting.ScreenMode {
        let rawValue = getValue(forKey: Constants.darkfiScreenMode.rawValue, default: selectedScreenMode.rawValue)
        return NighthawkSetting.ScreenMode(rawValue: rawValue) ?? .off
    }
    
    public func setScreenMode(_ mode: NighthawkSetting.ScreenMode) {
        setValue(mode.rawValue, forKey: Constants.darkfiScreenMode.rawValue)
    }
    
    public var syncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency {
        let rawValue = getValue(
            forKey: Constants.darkfiSyncNotificationFrequency.rawValue,
            default: selectedSyncNotificationFrequency.rawValue
        )
        return NighthawkSetting.SyncNotificationFrequency(rawValue: rawValue) ?? .off
    }
    
    public func setSyncNotificationFrequency(_ frequency: NighthawkSetting.SyncNotificationFrequency) {
        setValue(frequency.rawValue, forKey: Constants.darkfiSyncNotificationFrequency.rawValue)
    }
    
    public var areBiometricsEnabled: Bool {
        getValue(forKey: Constants.darkfiBiometricsEnabled.rawValue, default: biometricsEnabled)
    }
    
    public func setAreBiometricsEnabled(_ bool: Bool) {
        setValue(bool, forKey: Constants.darkfiBiometricsEnabled.rawValue)
    }
    
    public var isBandit: Bool {
        getValue(forKey: Constants.darkfiIsBandit.rawValue, default: bandit)
    }
    
    public func setIsBandit(_ bool: Bool) {
        setValue(bool, forKey: Constants.darkfiIsBandit.rawValue)
    }
    
    public var isFirstSync: Bool {
        getValue(forKey: Constants.darkfiIsFirstSync.rawValue, default: firstSync)
    }
    
    public func setIsFirstSync(_ bool: Bool) {
        setValue(bool, forKey: Constants.darkfiIsFirstSync.rawValue)
    }
    
    public var isUnstoppableDomainsEnabled: Bool {
        getValue(forKey: Constants.darkfiIsUnstoppableDomainsEnabled.rawValue, default: unstoppableDomainsEnabled)
    }
    
    public func setIsUnstoppableDomainsEnabled(_ bool: Bool) {
        setValue(bool, forKey: Constants.darkfiIsUnstoppableDomainsEnabled.rawValue)
    }
    
    public var hasShownAutoshielding: Bool {
        getValue(forKey: Constants.darkfiHasShownAutoshielding.rawValue, default: shownAutoshielding)
    }
    
    public func setHasShownAutoshielding(_ bool: Bool) {
        setValue(bool, forKey: Constants.darkfiHasShownAutoshielding.rawValue)
    }
    
    public var isUsingCustomLightwalletd: Bool {
        getValue(forKey: Constants.darkfiUseCustomLightwalletd.rawValue, default: useCustomLightwalletd)
    }
    
    public func setIsUsingCustomLightwalletd(_ bool: Bool) {
        setValue(bool, forKey: Constants.darkfiUseCustomLightwalletd.rawValue)
    }
    
    public var customLightwalletdServer: String? {
        getValue(forKey: Constants.darkfiCustomLightwalletdServer.rawValue, default: selectedCustomLightwalletdServer)
    }
    
    public func setCustomLightwalletdServer(_ string: String?) {
        if let string {
            setValue(string, forKey: Constants.darkfiCustomLightwalletdServer.rawValue)
        } else {
            userDefaults.remove(Constants.darkfiCustomLightwalletdServer.rawValue)
        }
    }
    
    // MARK: - Tor Network Preferences
    
    public var torForWalletEnabled: Bool {
        getValue(forKey: Constants.darkfiTorForWallet.rawValue, default: false)
    }
    
    public func setTorForWalletEnabled(_ enabled: Bool) {
        setValue(enabled, forKey: Constants.darkfiTorForWallet.rawValue)
    }
    
    public var torForChatEnabled: Bool {
        getValue(forKey: Constants.darkfiTorForChat.rawValue, default: false)
    }
    
    public func setTorForChatEnabled(_ enabled: Bool) {
        setValue(enabled, forKey: Constants.darkfiTorForChat.rawValue)
    }
    
    public var useEmbeddedTor: Bool {
        getValue(forKey: Constants.darkfiUseEmbeddedTor.rawValue, default: true)
    }
    
    public func setUseEmbeddedTor(_ enabled: Bool) {
        setValue(enabled, forKey: Constants.darkfiUseEmbeddedTor.rawValue)
    }
    
    public var torSocksHost: String? {
        getValue(forKey: Constants.darkfiTorSocksHost.rawValue, default: "127.0.0.1" as String?)
    }
    
    public func setTorSocksHost(_ host: String) {
        setValue(host, forKey: Constants.darkfiTorSocksHost.rawValue)
    }
    
    public var torSocksPort: String? {
        getValue(forKey: Constants.darkfiTorSocksPort.rawValue, default: "9050" as String?)
    }
    
    public func setTorSocksPort(_ port: String) {
        setValue(port, forKey: Constants.darkfiTorSocksPort.rawValue)
    }

    /// Whether the user confirmed they wrote down their 22-word recovery phrase.
    public var isUserBackupComplete: Bool {
        getValue(forKey: Constants.darkfiIsUserBackupComplete.rawValue, default: false)
    }

    public func setIsUserBackupComplete(_ complete: Bool) {
        setValue(complete, forKey: Constants.darkfiIsUserBackupComplete.rawValue)
    }

    // MARK: - Chat settings

    public var runEmbeddedDarkirc: Bool {
        getValue(forKey: Constants.darkfiRunEmbeddedDarkirc.rawValue, default: true)
    }

    public func setRunEmbeddedDarkirc(_ enabled: Bool) {
        setValue(enabled, forKey: Constants.darkfiRunEmbeddedDarkirc.rawValue)
    }

    public var darkircDagsCount: Int {
        getValue(forKey: Constants.darkfiDarkircDagsCount.rawValue, default: 8)
    }

    public func setDarkircDagsCount(_ count: Int) {
        setValue(count, forKey: Constants.darkfiDarkircDagsCount.rawValue)
    }

    public var darkircFastMode: Bool {
        getValue(forKey: Constants.darkfiDarkircFastMode.rawValue, default: false)
    }

    public func setDarkircFastMode(_ enabled: Bool) {
        setValue(enabled, forKey: Constants.darkfiDarkircFastMode.rawValue)
    }

    // MARK: - Chat Secrets (Keychain-backed via ChatSecureStorage)

    public var dmPublicKey: String? {
        chatSecure.dmPublicKey
    }

    public func setDmPublicKey(_ key: String?) {
        chatSecure.setDmPublicKey(key)
    }

    public var dmSecretKey: String? {
        chatSecure.dmSecretKey
    }

    public func setDmSecretKey(_ key: String?) {
        chatSecure.setDmSecretKey(key)
    }

    public var encryptedChannelsJSON: String? {
        chatSecure.encryptedChannelsJSON
    }

    public func setEncryptedChannelsJSON(_ json: String?) {
        chatSecure.setEncryptedChannelsJSON(json)
    }

    public var encryptedContactsJSON: String? {
        chatSecure.encryptedContactsJSON
    }

    public func setEncryptedContactsJSON(_ json: String?) {
        chatSecure.setEncryptedContactsJSON(json)
    }

    /// Use carefully: Deletes all user preferences and chat secrets.
    public func removeAll() {
        for key in Constants.allCases {
            userDefaults.remove(key.rawValue)
        }
        chatSecure.removeAll()
    }
}

extension UserPreferencesStorage {
    public static let live = UserPreferencesStorage(
        icon: .default,
        defaultTheme: .default,
        currency: .off,
        selectedScreenMode: .keepOn,
        selectedSyncNotificationFrequency: .off,
        biometricsEnabled: false,
        bandit: false,
        firstSync: true,
        unstoppableDomainsEnabled: false,
        shownAutoshielding: false,
        useCustomLightwalletd: false,
        selectedCustomLightwalletdServer: nil,
        userDefaults: .live()
    )
}

private extension UserPreferencesStorage {
    func getValue<Value>(forKey: String, default defaultIfNil: Value) -> Value {
        userDefaults.objectForKey(forKey) as? Value ?? defaultIfNil
    }

    func setValue<Value>(_ value: Value, forKey: String) {
        userDefaults.setValue(value, forKey)
    }
}
