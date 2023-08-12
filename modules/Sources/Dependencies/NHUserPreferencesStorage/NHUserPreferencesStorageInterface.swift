//
//  NHUserPreferencesStorageInterface.swift
//  secant-testnet
//
//  Created by Matthew Watt on 08/03/2023.
//

import Foundation
import ComposableArchitecture
import Models

extension DependencyValues {
    public var nhUserStoredPreferences: NHUserPreferencesStorageClient {
        get { self[NHUserPreferencesStorageClient.self] }
        set { self[NHUserPreferencesStorageClient.self] = newValue }
    }
}

public struct NHUserPreferencesStorageClient {
    public var currency: () -> String
    public var setCurrency: (String) -> Void

    public var isFiatConverted: () -> Bool
    public var setIsFiatConverted: (Bool) -> Void
    
    public var screenMode: () -> NighthawkSetting.ScreenMode
    public var setScreenMode: (NighthawkSetting.ScreenMode) -> Void

    public var removeAll: () -> Void
}
