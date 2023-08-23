//
//  NHUserPreferencesStorage.swift
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
public struct NHUserPreferencesStorage {
    public enum Constants: String, CaseIterable {
        case zcashCurrency
        case zcashFiatConverted
        case zcashScreenMode
        case zcashSyncNotificationFrequency
    }
    
    /// Default values for all preferences in case there is no value stored (counterparts to `Constants`)
    private let convertedCurrency: String
    private let fiatConversion: Bool
    private let selectedScreenMode: NighthawkSetting.ScreenMode
    private let selectedSyncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency
    
    private let userDefaults: UserDefaultsClient
    
    public init(
        convertedCurrency: String,
        fiatConversion: Bool,
        selectedScreenMode: NighthawkSetting.ScreenMode,
        selectedSyncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency,
        userDefaults: UserDefaultsClient
    ) {
        self.convertedCurrency = convertedCurrency
        self.fiatConversion = fiatConversion
        self.selectedScreenMode = selectedScreenMode
        self.selectedSyncNotificationFrequency = selectedSyncNotificationFrequency
        self.userDefaults = userDefaults
    }

    public var currency: String {
        getValue(forKey: Constants.zcashCurrency.rawValue, default: convertedCurrency)
    }
    
    public func setCurrency(_ string: String) {
        setValue(string, forKey: Constants.zcashCurrency.rawValue)
    }

    public var isFiatConverted: Bool {
        getValue(forKey: Constants.zcashFiatConverted.rawValue, default: fiatConversion)
    }

    public func setIsFiatConverted(_ bool: Bool) {
        setValue(bool, forKey: Constants.zcashFiatConverted.rawValue)
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

    /// Use carefully: Deletes all user preferences from the User Defaults
    public func removeAll() {
        for key in Constants.allCases {
            userDefaults.remove(key.rawValue)
        }
    }
}

private extension NHUserPreferencesStorage {
    func getValue<Value>(forKey: String, default defaultIfNil: Value) -> Value {
        userDefaults.objectForKey(forKey) as? Value ?? defaultIfNil
    }

    func setValue<Value>(_ value: Value, forKey: String) {
        userDefaults.setValue(value, forKey)
    }
}
