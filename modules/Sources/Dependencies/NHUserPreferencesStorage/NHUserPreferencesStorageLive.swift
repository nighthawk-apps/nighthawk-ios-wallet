//
//  NHUserPreferencesStorageLive.swift
//  secant-testnet
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import ComposableArchitecture

extension NHUserPreferencesStorageClient: DependencyKey {
    public static var liveValue: NHUserPreferencesStorageClient = {
        let live = NHUserPreferencesStorage.live

        return NHUserPreferencesStorageClient(
            currency: { live.currency },
            setCurrency: live.setCurrency(_:),
            isFiatConverted: { live.isFiatConverted },
            setIsFiatConverted: live.setIsFiatConverted(_:),
            screenMode: { live.screenMode },
            setScreenMode: live.setScreenMode(_:),
            removeAll: live.removeAll
        )
    }()
}

extension NHUserPreferencesStorage {
    public static let live = NHUserPreferencesStorage(
        convertedCurrency: "USD",
        fiatConversion: true,
        selectedScreenMode: .off,
        userDefaults: .live()
    )
}
