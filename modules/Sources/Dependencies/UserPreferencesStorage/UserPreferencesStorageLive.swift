//
//  UserPreferencesStorageLive.swift
//  secant-testnet
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import ComposableArchitecture

extension UserPreferencesStorageClient: DependencyKey {
    public static var liveValue: UserPreferencesStorageClient = {
        let live = UserPreferencesStorage.live

        return UserPreferencesStorageClient(
            currency: { live.currency },
            setCurrency: live.setCurrency(_:),
            isFiatConverted: { live.isFiatConverted },
            setIsFiatConverted: live.setIsFiatConverted(_:),
            screenMode: { live.screenMode },
            setScreenMode: live.setScreenMode(_:),
            syncNotificationFrequency: { live.syncNotificationFrequency },
            setSyncNotificationFrequency: live.setSyncNotificationFrequency(_:),
            areBiometricsEnabled: { live.areBiometricsEnabled },
            setAreBiometricsEnabled: live.setAreBiometricsEnabled(_:),
            removeAll: live.removeAll
        )
    }()
}

extension UserPreferencesStorage {
    public static let live = UserPreferencesStorage(
        convertedCurrency: "USD",
        fiatConversion: true,
        selectedScreenMode: .off,
        selectedSyncNotificationFrequency: .off,
        biometricsEnabled: false,
        userDefaults: .live()
    )
}
