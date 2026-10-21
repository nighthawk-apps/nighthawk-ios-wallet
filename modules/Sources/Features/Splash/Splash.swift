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
        /// Once the user has been routed past splash, avoid sending them back to welcome
        /// when splash reappears after background lock / scene phase changes.
        public var hasCompletedInitialRoute = false
        /// Holds the splash on a Nym bootstrap, with a progress estimate and a skip.
        public var waitingForNym = false
        public var nymFailed = false
        public var nymSkipped = false
        public var nymStartedAt: Date?
        public var pendingLaunch: PendingLaunch?
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
        case nymReady
        case nymFailed
        case retryNym
        case continueWithoutNym

        public enum Alert: Equatable {}

        public enum Delegate: Equatable {
            case handleNewUser
            case handleMigration
            case handleNeedsBackup
            case initializeSDKAndLaunchWallet
        }
    }

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
                if state.waitingForNym { return .none }
                state.initializationState = Splash.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    darkfiNetwork: "testnet"
                )
                let pending = Splash.pendingLaunch(
                    initializationState: state.initializationState,
                    backupComplete: userStoredPreferences.isUserBackupComplete(),
                    biometricsEnabled: userStoredPreferences.areBiometricsEnabled()
                )
                let holdForNym =
                    !state.nymSkipped &&
                    userStoredPreferences.walletPrivacyNetwork() == .nym &&
                    !DarkfiFfiSafe.isNymRunning() &&
                    !pending.isTerminalFailure
                if holdForNym {
                    state.pendingLaunch = pending
                    state.waitingForNym = true
                    state.nymFailed = false
                    state.nymStartedAt = date()
                    return nymPollEffect()
                }
                return launchEffect(pending, state: &state)
            case .nymReady:
                guard state.waitingForNym, let pending = state.pendingLaunch else { return .none }
                state.waitingForNym = false
                return launchEffect(pending, state: &state)
            case .nymFailed:
                state.nymFailed = true
                return .none
            case .retryNym:
                guard state.waitingForNym else { return .none }
                state.nymFailed = false
                state.nymStartedAt = date()
                return nymPollEffect()
            case .continueWithoutNym:
                guard state.waitingForNym, let pending = state.pendingLaunch else { return .none }
                state.waitingForNym = false
                state.nymSkipped = true
                userStoredPreferences.setWalletPrivacyNetwork(.direct)
                DarkfiFfiSafe.stopNymProxy()
                return .merge(
                    .cancel(id: CancelID.nymPoll),
                    launchEffect(pending, state: &state)
                )
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

    private enum CancelID { case nymPoll }

    private func nymPollEffect() -> Effect<Action> {
        .run { send in
            if !DarkfiFfiSafe.isNymRunning() {
                _ = DarkfiFfiSafe.startNymProxySafely(
                    socksPort: NighthawkSetting.PrivacyNetwork.nymSocksPort
                )
            }
            for _ in 0..<240 {
                if DarkfiFfiSafe.isNymRunning() {
                    await send(.nymReady)
                    return
                }
                if DarkfiFfiSafe.nymStatus() == "failed" {
                    await send(.nymFailed)
                    return
                }
                try await Task.sleep(for: .milliseconds(500))
            }
            await send(.nymFailed)
        }
        .cancellable(id: CancelID.nymPoll, cancelInFlight: true)
    }

    private func launchEffect(_ pending: PendingLaunch, state: inout State) -> Effect<Action> {
        switch pending {
        case let .failed(initializationState):
            state.alert = AlertState.walletStateFailed(initializationState)
            return .none
        case .migration:
            return .send(.delegate(.handleMigration))
        case .needsBackup:
            return .send(.delegate(.handleNeedsBackup))
        case .authenticate:
            return .send(.authenticate)
        case .launchWallet:
            return .send(.delegate(.initializeSDKAndLaunchWallet))
        case .newUser:
            guard !state.hasCompletedInitialRoute else {
                state.alert = AlertState.walletStateFailed(.uninitialized)
                return .none
            }
            return .send(.delegate(.handleNewUser))
        }
    }

    public init() {}
}

public extension Splash {
    enum PendingLaunch: Equatable {
        case failed(InitializationState)
        case migration
        case needsBackup
        case authenticate
        case launchWallet
        case newUser

        var isTerminalFailure: Bool {
            if case .failed = self { return true }
            return false
        }
    }

    static func pendingLaunch(
        initializationState: InitializationState,
        backupComplete: Bool,
        biometricsEnabled: Bool
    ) -> PendingLaunch {
        switch initializationState {
        case .failed, .keysMissing:
            return .failed(initializationState)
        case .needsMigration:
            return .migration
        case .initialized, .filesMissing:
            if !backupComplete { return .needsBackup }
            if biometricsEnabled { return .authenticate }
            return .launchWallet
        case .uninitialized:
            return .newUser
        }
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
