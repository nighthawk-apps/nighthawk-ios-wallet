//
//  NHUserPreferencesStorageMocks.swift
//  secant-testnet
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import ComposableArchitecture

extension NHUserPreferencesStorageClient: TestDependencyKey {
    public static var testValue = {
        let mock = NHUserPreferencesStorage.mock

        return NHUserPreferencesStorageClient(
            currency: { mock.currency },
            setCurrency: mock.setCurrency(_:),
            isFiatConverted: { mock.isFiatConverted },
            setIsFiatConverted: mock.setIsFiatConverted(_:),
            screenMode: { mock.screenMode },
            setScreenMode: mock.setScreenMode(_:),
            removeAll: mock.removeAll
        )
    }()
}

extension NHUserPreferencesStorage {
    public static let mock = NHUserPreferencesStorage(
        convertedCurrency: "USD",
        fiatConversion: true,
        selectedScreenMode: .off,
        userDefaults: .noOp
    )
}