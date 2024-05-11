//
//  UserPreferencesStorage.swift
//  secant-testnet
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import Models
import UserDefaults

/// Live implementation of the `UserPreferences` using User Defaults
/// according to https://developer.apple.com/documentation/foundation/userdefaults
/// the UserDefaults class is thread-safe.
public struct UserPreferencesStorage {
    public enum Constants: String, CaseIterable {
        case zcashAppIcon
        case zcashTheme
        case zcashFiatCurrency
        case zcashScreenMode
        case zcashSyncNotificationFrequency
        case zcashBiometricsEnabled
        case zcashIsBandit
        case zcashIsFirstSync
        case zcashIsUnstoppableDomainsEnabled
        case zcashHasShownAutoshielding
        case zcashUseCustomLightwalletd
        case zcashCustomLightwalletdServer
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
        let rawValue = getValue(forKey: Constants.zcashAppIcon.rawValue, default: icon.rawValue)
        return NighthawkSetting.AppIcon(rawValue: rawValue) ?? .default
    }
    
    public func setAppIcon(_ icon: NighthawkSetting.AppIcon) {
        setValue(icon.rawValue, forKey: Constants.zcashAppIcon.rawValue)
    }
    
    public var theme: NighthawkSetting.Theme {
        let rawValue = getValue(forKey: Constants.zcashTheme.rawValue, default: defaultTheme.rawValue)
        return NighthawkSetting.Theme(rawValue: rawValue) ?? .default
    }
    
    public func setTheme(_ theme: NighthawkSetting.Theme) {
        setValue(theme.rawValue, forKey: Constants.zcashTheme.rawValue)
    }

    public var fiatCurrency: NighthawkSetting.FiatCurrency {
        let rawValue = getValue(forKey: Constants.zcashFiatCurrency.rawValue, default: currency.rawValue)
        return NighthawkSetting.FiatCurrency(rawValue: rawValue) ?? .off
    }
    
    public func setFiatCurrency(_ currency: NighthawkSetting.FiatCurrency) {
        setValue(currency.rawValue, forKey: Constants.zcashFiatCurrency.rawValue)
    }

    public var screenMode: NighthawkSetting.ScreenMode {
        let rawValue = getValue(forKey: Constants.zcashScreenMode.rawValue, default: selectedScreenMode.rawValue)
        return NighthawkSetting.ScreenMode(rawValue: rawValue) ?? .off
    }
    
    public func setScreenMode(_ mode: NighthawkSetting.ScreenMode) {
        setValue(mode.rawValue, forKey: Constants.zcashScreenMode.rawValue)
    }
    
    public var syncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency {
        let rawValue = getValue(
            forKey: Constants.zcashSyncNotificationFrequency.rawValue,
            default: selectedSyncNotificationFrequency.rawValue
        )
        return NighthawkSetting.SyncNotificationFrequency(rawValue: rawValue) ?? .off
    }
    
    public func setSyncNotificationFrequency(_ frequency: NighthawkSetting.SyncNotificationFrequency) {
        setValue(frequency.rawValue, forKey: Constants.zcashSyncNotificationFrequency.rawValue)
    }
    
    public var areBiometricsEnabled: Bool {
        getValue(forKey: Constants.zcashBiometricsEnabled.rawValue, default: biometricsEnabled)
    }
    
    public func setAreBiometricsEnabled(_ bool: Bool) {
        setValue(bool, forKey: Constants.zcashBiometricsEnabled.rawValue)
    }
    
    public var isBandit: Bool {
        getValue(forKey: Constants.zcashIsBandit.rawValue, default: bandit)
    }
    
    public func setIsBandit(_ bool: Bool) {
        setValue(bool, forKey: Constants.zcashIsBandit.rawValue)
    }
    
    public var isFirstSync: Bool {
        getValue(forKey: Constants.zcashIsFirstSync.rawValue, default: firstSync)
    }
    
    public func setIsFirstSync(_ bool: Bool) {
        setValue(bool, forKey: Constants.zcashIsFirstSync.rawValue)
    }
    
    public var isUnstoppableDomainsEnabled: Bool {
        getValue(forKey: Constants.zcashIsUnstoppableDomainsEnabled.rawValue, default: unstoppableDomainsEnabled)
    }
    
    public func setIsUnstoppableDomainsEnabled(_ bool: Bool) {
        setValue(bool, forKey: Constants.zcashIsUnstoppableDomainsEnabled.rawValue)
    }
    
    public var hasShownAutoshielding: Bool {
        getValue(forKey: Constants.zcashHasShownAutoshielding.rawValue, default: shownAutoshielding)
    }
    
    public func setHasShownAutoshielding(_ bool: Bool) {
        setValue(bool, forKey: Constants.zcashHasShownAutoshielding.rawValue)
    }
    
    public var isUsingCustomLightwalletd: Bool {
        getValue(forKey: Constants.zcashUseCustomLightwalletd.rawValue, default: useCustomLightwalletd)
    }
    
    public func setIsUsingCustomLightwalletd(_ bool: Bool) {
        setValue(bool, forKey: Constants.zcashUseCustomLightwalletd.rawValue)
    }
    
    public var customLightwalletdServer: String? {
        getValue(forKey: Constants.zcashCustomLightwalletdServer.rawValue, default: selectedCustomLightwalletdServer)
    }
    
    public func setCustomLightwalletdServer(_ string: String?) {
        if let string {
            setValue(string, forKey: Constants.zcashCustomLightwalletdServer.rawValue)
        } else {
            userDefaults.remove(Constants.zcashCustomLightwalletdServer.rawValue)
        }
    }


    /// Use carefully: Deletes all user preferences from the User Defaults
    public func removeAll() {
        for key in Constants.allCases {
            userDefaults.remove(key.rawValue)
        }
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
