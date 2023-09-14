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
import UserPreferencesStorage
import Utils
import WalletStorage
import ZcashLightClientKit

public struct Splash: ReducerProtocol {
    let zcashNetwork: ZcashNetwork
    
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        public var hasAuthenticated = false
        public var initializationState = InitializationState.uninitialized
        public var biometricsEnabled: Bool {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return userStoredPreferences.areBiometricsEnabled()
        }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case authenticate
        case authenticationResponse(Bool)
        case checkWalletInitialization
        case delegate(Delegate)
        case onAppear
        case retryTapped
        
        public enum Alert: Equatable {}
        
        public enum Delegate: Equatable {
            case handleNewUser
            case handleMigration
            case initializeSDKAndLaunchWallet
        }
    }
    
    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage
    
    public var body: some ReducerProtocolOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .authenticate, .retryTapped:
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
                state.hasAuthenticated = authenticated
                return .none
            case .checkWalletInitialization:
                state.initializationState = Splash.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    zcashNetwork: zcashNetwork
                )
                
                switch state.initializationState {
                case .failed:
                    state.alert = AlertState.walletStateFailed(state.initializationState)
                    return .none
                case .needsMigration:
                    return .run { send in await send(.delegate(.handleMigration)) }
                case .keysMissing:
                    state.alert = AlertState.walletStateFailed(state.initializationState)
                    return .none
                case .initialized, .filesMissing:
                    if userStoredPreferences.areBiometricsEnabled() {
                        return .run { send in await send(.authenticate) }
                    } else {
                        return .run { send in await send(.delegate(.initializeSDKAndLaunchWallet)) }
                    }
                case .uninitialized:
                    return .run { send in await send(.delegate(.handleNewUser)) }
                }
            case .delegate:
                return .none
            case .onAppear:
                return .run { send in
                    /// We need to fetch data from keychain, in order to be 100% sure the keychain can be read we delay the check a bit
                    try await Task.sleep(seconds: 0.5)
                    await send(.checkWalletInitialization)
                }
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }
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
