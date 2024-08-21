//
//  Splash.swift
//  
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import DatabaseFiles
import Generated
import LocalAuthenticationClient
import Models
import ProcessInfoClient
import SwiftUI
import UserPreferencesStorage
import Utils
import WalletStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct Splash {
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var authenticated: Bool { lastAuthenticatedTime != nil }
        public var isFirstLaunch = true
        public var hasAttemptedAuthentication = false
        public var initializationState = InitializationState.uninitialized
        public var isAuthenticating = false
        public var lastAuthenticatedTime: Date?
        public var lastInactiveTime: Date?
        public var phase = ScenePhase.background
        public var isVisible = true
        public var shouldHandleScenePhaseChange: Bool {
            isVisible && !isAuthenticating && !hasAttemptedAuthentication
        }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case authenticate
        case authenticationResponse(Bool)
        case checkWalletInitialization
        case delegate(Delegate)
        case onDisappear
        case onAppear
        case retryTapped
        case scenePhaseChanged(ScenePhase)
        
        public enum Alert: Equatable {}
        
        public enum Delegate: Equatable {
            case handleNewUser
            case handleMigration
            case initializeSDKAndLaunchWallet
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.processInfo) var processInfo
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .authenticate, .retryTapped:
                state.isAuthenticating = true
                return .run { send in
                    let context = localAuthenticationContext()
                    
                    if (try? context.canEvaluatePolicy(.deviceOwnerAuthentication)) == true {
                        let success = (
                            try? await context.evaluatePolicy(
                                .deviceOwnerAuthentication,
                                L10n.Nighthawk.LocalAuthentication.accessWalletReason
                            )
                        ) ?? false
                        await send(.authenticationResponse(success))
                        if success {
                            await send(.delegate(.initializeSDKAndLaunchWallet))
                        }
                    }
                }
            case let .authenticationResponse(authenticated):
                state.hasAttemptedAuthentication = true
                state.isAuthenticating = false
                if authenticated {
                    state.lastAuthenticatedTime = date()
                }
                return .none
            case .checkWalletInitialization:
                state.initializationState = Splash.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    zcashNetwork: zcashSDKEnvironment.network
                )
                
                switch state.initializationState {
                case .failed:
                    state.alert = AlertState.walletStateFailed(state.initializationState)
                    return .none
                case .needsMigration:
                    return .send(.delegate(.handleMigration))
                case .keysMissing:
                    state.alert = AlertState.walletStateFailed(state.initializationState)
                    return .none
                case .initialized, .filesMissing:
                    if userStoredPreferences.areBiometricsEnabled() {
                        return .send(.authenticate)
                    } else {
                        return .send(.delegate(.initializeSDKAndLaunchWallet))
                    }
                case .uninitialized:
                    return .send(.delegate(.handleNewUser))
                }
            case .delegate:
                return .none
            case .onAppear:
                defer { state.isFirstLaunch = false }
                state.isVisible = true
                if processInfo.isiOSAppOnMac() && state.isFirstLaunch {
                    return .run { send in
                        /// We need to fetch data from keychain, in order to be 100% sure the keychain can be read we delay the check a bit
                        try await clock.sleep(for: .seconds(0.5))
                        await send(.checkWalletInitialization)
                    }
                } else {
                    if !state.isFirstLaunch && state.shouldHandleScenePhaseChange {
                        return .run { send in
                            /// We need to fetch data from keychain, in order to be 100% sure the keychain can be read we delay the check a bit
                            try await clock.sleep(for: .seconds(0.5))
                            await send(.checkWalletInitialization)
                        }
                    }
                    return .none
                }
            case .onDisappear:
                state.isVisible = false
                return .none
            case let .scenePhaseChanged(newPhase):
                if newPhase == .active && state.shouldHandleScenePhaseChange {
                    return .run { send in
                        /// We need to fetch data from keychain, in order to be 100% sure the keychain can be read we delay the check a bit
                        try await clock.sleep(for: .seconds(0.5))
                        await send(.checkWalletInitialization)
                    }
                }
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    public init() {}
}

// MARK: - Alerts
extension AlertState
where Action == Splash.Action.Alert {
    public static func walletStateFailed(_ walletState: InitializationState) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.Splash.Initialization.Alert.Failed.title)
        } message: {
            TextState(L10n.Nighthawk.Splash.Initialization.Alert.WalletStateFailed.message(walletState))
        }
    }
}

// MARK: - Wallet initialization
private extension Splash {
    static func walletInitializationState(
        databaseFiles: DatabaseFilesClient,
        walletStorage: WalletStorageClient,
        zcashNetwork: ZcashNetwork
    ) -> InitializationState {
        var keysPresent = false
        do {
            keysPresent = try walletStorage.areKeysPresent()
            let databaseFilesPresent = databaseFiles.areDbFilesPresentFor(
                zcashNetwork
            )
            
            switch (keysPresent, databaseFilesPresent) {
            case (false, false):
                return .uninitialized
            case (false, true):
                return .keysMissing
            case (true, false):
                return .filesMissing
            case (true, true):
                return .initialized
            }
        } catch WalletStorage.WalletStorageError.uninitializedWallet {
            if walletStorage.areLegacyKeysPresent() {
                return .needsMigration
            }
            
            if databaseFiles.areDbFilesPresentFor(zcashNetwork) {
                return .keysMissing
            }
        } catch {
            return .failed
        }
        
        return .uninitialized
    }
}
