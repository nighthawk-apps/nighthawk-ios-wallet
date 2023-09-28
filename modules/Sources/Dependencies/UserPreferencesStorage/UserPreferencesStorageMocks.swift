//
//  UserPreferencesStorageMocks.swift
//  secant-testnet
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import ComposableArchitecture

extension UserPreferencesStorageClient: TestDependencyKey {
    public static var testValue = {
        let mock = UserPreferencesStorage.mock

        return UserPreferencesStorageClient(
            currency: { mock.currency },
            setCurrency: mock.setCurrency(_:),
            isFiatConverted: { mock.isFiatConverted },
            setIsFiatConverted: mock.setIsFiatConverted(_:),
            screenMode: { mock.screenMode },
            setScreenMode: mock.setScreenMode(_:),
            syncNotificationFrequency: { mock.syncNotificationFrequency },
            setSyncNotificationFrequency: mock.setSyncNotificationFrequency(_:),
            areBiometricsEnabled: { mock.areBiometricsEnabled },
            setAreBiometricsEnabled: mock.setAreBiometricsEnabled(_:),
            isFirstSync: { mock.isFirstSync },
            setIsFirstSync: mock.setIsFirstSync(_:),
            removeAll: mock.removeAll
        )
    }()
}

extension UserPreferencesStorage {
    public static let mock = UserPreferencesStorage(
        convertedCurrency: "USD",
        fiatConversion: true,
        selectedScreenMode: .off,
        selectedSyncNotificationFrequency: .off,
        biometricsEnabled: false,
        userDefaults: .noOp,
        firstSync: true
    )
}
