//
//  Splash.swift
//
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import DarkfiCore
import DatabaseFiles
import Generated
import LocalAuthenticationClient
import Models
import SwiftUI
import UserPreferencesStorage
import Utils
import WalletStorage

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
        /// Status line under the logo (e.g. Tor bootstrap while opening the wallet).
        public var statusMessage: String?
        /// Show “Continue without Tor” while bootstrap is in progress or failed.
        public var showDisableTorButton = false
        /// Once the user has been routed past splash, avoid sending them back to welcome
        /// when splash reappears after background lock / scene phase changes.
        public var hasCompletedInitialRoute = false
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
        case bootstrapTorThenLaunch
        case torBootstrapFailed
        case disableTorAndContinue
        case delegate(Delegate)
        case onDisappear
        case onAppear
        case retryTapped
        case scenePhaseChanged(ScenePhase)
        case statusMessageUpdated(String?)

        public enum Alert: Equatable {}

        public enum Delegate: Equatable {
            case handleNewUser
            case handleMigration
            case handleNeedsBackup
            case initializeSDKAndLaunchWallet
        }
    }

    private enum CancelID { case torBootstrap }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage

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
                    }
                }
            case let .authenticationResponse(authenticated):
                state.hasAttemptedAuthentication = true
                state.isAuthenticating = false
                if authenticated {
                    state.lastAuthenticatedTime = date()
                    return .send(.bootstrapTorThenLaunch)
                }
                return .none
            case .bootstrapTorThenLaunch:
                let torOn = userStoredPreferences.torForWalletEnabled()
                    || userStoredPreferences.torForChatEnabled()
                let socksPort = UInt16(userStoredPreferences.torSocksPort() ?? "9050") ?? 9050
                if !torOn {
                    state.statusMessage = nil
                    state.showDisableTorButton = false
                    return .send(.delegate(.initializeSDKAndLaunchWallet))
                }
                state.statusMessage = "Tor bootstrapping…"
                state.showDisableTorButton = true
                return .run { send in
                    let ready = await TorBootstrap.ensureReady(socksPort: socksPort)
                    if ready {
                        await send(.statusMessageUpdated(nil))
                        await send(.delegate(.initializeSDKAndLaunchWallet))
                    } else {
                        await send(.torBootstrapFailed)
                    }
                }
                .cancellable(id: CancelID.torBootstrap, cancelInFlight: true)
            case .torBootstrapFailed:
                state.statusMessage = "Tor bootstrap failed — retry or continue without Tor"
                state.showDisableTorButton = true
                state.hasAttemptedAuthentication = true
                return .none
            case .disableTorAndContinue:
                // Persist clearnet as the user's default; Settings can re-enable Tor later.
                userStoredPreferences.setTorForWalletEnabled(false)
                userStoredPreferences.setTorForChatEnabled(false)
                DarkfiFfiSafe.stopArtiProxy()
                state.statusMessage = nil
                state.showDisableTorButton = false
                return .merge(
                    .cancel(id: CancelID.torBootstrap),
                    .send(.delegate(.initializeSDKAndLaunchWallet))
                )
            case let .statusMessageUpdated(message):
                state.statusMessage = message
                if message == nil {
                    state.showDisableTorButton = false
                }
                return .none
            case .checkWalletInitialization:
                state.initializationState = Splash.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    darkfiNetwork: "testnet"
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
                    if !userStoredPreferences.isUserBackupComplete() {
                        return .send(.delegate(.handleNeedsBackup))
                    }
                    if userStoredPreferences.areBiometricsEnabled() {
                        return .send(.authenticate)
                    } else {
                        return .send(.bootstrapTorThenLaunch)
                    }
                case .uninitialized:
                    guard !state.hasCompletedInitialRoute else {
                        state.alert = AlertState.walletStateFailed(.uninitialized)
                        return .none
                    }
                    return .send(.delegate(.handleNewUser))
                }
            case .delegate:
                return .none
            case .onAppear:
                defer { state.isFirstLaunch = false }
                state.isVisible = true
                if state.isFirstLaunch || state.shouldHandleScenePhaseChange {
                    return .run { send in
                        /// We need to fetch data from keychain, in order to be 100% sure the keychain can be read we delay the check a bit
                        try await clock.sleep(for: .seconds(0.5))
                        await send(.checkWalletInitialization)
                    }
                }
                return .none
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
        darkfiNetwork: DarkFiNetwork
    ) -> InitializationState {
        var keysPresent = false
        do {
            keysPresent = try walletStorage.areKeysPresent()
            let databaseFilesPresent = databaseFiles.areDbFilesPresentFor(
                darkfiNetwork
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

            if databaseFiles.areDbFilesPresentFor(darkfiNetwork) {
                return .keysMissing
            }
        } catch {
            return .failed
        }

        return .uninitialized
    }
}
