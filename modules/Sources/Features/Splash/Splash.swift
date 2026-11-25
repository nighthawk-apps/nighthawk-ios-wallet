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
        /// Once the user has been routed past splash, avoid sending them back to welcome
        /// when splash reappears after background lock / scene phase changes.
        public var hasCompletedInitialRoute = false
        /// True while a delayed wallet check is already scheduled. Cold start fires
        /// both `onAppear` and `scenePhaseChanged(.active)`; the second one must not
        /// run another check.
        public var walletCheckPending = false
        /// Holds the splash on a Nym bootstrap, with a progress estimate and a skip.
        public var waitingForNym = false
        public var nymFailed = false
        public var nymSkipped = false
        public var nymStartedAt: Date?
        public var pendingLaunch: PendingLaunch?
        /// 6-digit App PIN unlock state when PIN lock is configured.
        public var requiresPinEntry = false
        public var pinInput = ""
        public var pinError: String?

        public var shouldHandleScenePhaseChange: Bool {
            isVisible && !isAuthenticating && !hasAttemptedAuthentication && !requiresPinEntry
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
        case pinInputChanged(String)
        case submitPinTapped

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
                let biometricsEnabled = userStoredPreferences.areBiometricsEnabled()
                let pinSet = SecurityPinStore.isPinSet()
                if !biometricsEnabled && pinSet {
                    state.isAuthenticating = false
                    state.requiresPinEntry = true
                    state.pinInput = ""
                    state.pinError = nil
                    return .none
                }

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
                    } else if pinSet {
                        await send(.authenticationResponse(false))
                    } else {
                        // Device has no passcode/biometry/PIN configured — do not trap the user on Splash.
                        await send(.authenticationResponse(true))
                        await send(.delegate(.initializeSDKAndLaunchWallet))
                    }
                }
            case let .authenticationResponse(authenticated):
                state.hasAttemptedAuthentication = true
                state.isAuthenticating = false
                if authenticated {
                    state.requiresPinEntry = false
                    state.pinInput = ""
                    state.pinError = nil
                    state.lastAuthenticatedTime = date()
                } else if SecurityPinStore.isPinSet() {
                    state.requiresPinEntry = true
                }
                return .none
            case let .pinInputChanged(raw):
                state.pinInput = String(raw.filter(\.isNumber).prefix(SecurityPinStore.pinLength))
                state.pinError = nil
                return .none
            case .submitPinTapped:
                guard SecurityPinStore.isValidPinFormat(state.pinInput) else {
                    state.pinError = "Enter your 6-digit PIN."
                    return .none
                }
                if SecurityPinStore.verifyPin(state.pinInput) {
                    state.requiresPinEntry = false
                    state.pinInput = ""
                    state.pinError = nil
                    state.hasAttemptedAuthentication = true
                    state.lastAuthenticatedTime = date()
                    return .send(.delegate(.initializeSDKAndLaunchWallet))
                } else {
                    state.pinInput = ""
                    state.pinError = "Incorrect PIN. Try again."
                    return .none
                }
            case .checkWalletInitialization:
                state.walletCheckPending = false
                if state.waitingForNym { return .none }
                state.initializationState = Splash.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    darkfiNetwork: DarkfiNetwork.activeLabel
                )
                let authRequired = userStoredPreferences.areBiometricsEnabled() || SecurityPinStore.isPinSet()
                let pending = Splash.pendingLaunch(
                    initializationState: state.initializationState,
                    backupComplete: userStoredPreferences.isUserBackupComplete(),
                    biometricsEnabled: authRequired
                )
                let shouldWaitForNym =
                    !state.nymSkipped &&
                    !SessionPrivacyOverride.forceDirectThisSession &&
                    userStoredPreferences.walletPrivacyNetwork() == .nym &&
                    !DarkfiFfiSafe.isNymRunning() &&
                    !pending.isTerminalFailure
                if shouldWaitForNym {
                    state.pendingLaunch = pending
                    state.waitingForNym = true
                    state.nymFailed = false
                    state.nymStartedAt = date()
                    return nymPollEffect()
                }
                state.pendingLaunch = nil
                return launchEffect(pending, state: &state)
            case .nymReady:
                state.waitingForNym = false
                state.nymFailed = false
                guard let pending = state.pendingLaunch else {
                    return .none
                }
                state.pendingLaunch = nil
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
                state.waitingForNym = false
                state.nymFailed = false
                state.nymSkipped = true
                // Session-only Direct — do not permanently downgrade stored privacy prefs.
                SessionPrivacyOverride.setForceDirectThisSession(true)
                DarkfiFfiSafe.stopNymProxy()
                TransportHooks.continueWithoutNym()
                guard let pending = state.pendingLaunch else {
                    return .cancel(id: CancelID.nymPoll)
                }
                state.pendingLaunch = nil
                return .merge(
                    .cancel(id: CancelID.nymPoll),
                    launchEffect(pending, state: &state)
                )
            case .delegate:
                return .none
            case .onAppear:
                let alreadyVisible = state.isVisible
                let firstLaunch = state.isFirstLaunch
                state.isVisible = true
                state.isFirstLaunch = false
                // SplashView.onAppear and AppView's path onChange both send this.
                // A second call while splash is already visible must not start another check.
                if alreadyVisible && !firstLaunch {
                    return .none
                }
                if firstLaunch || state.shouldHandleScenePhaseChange {
                    return scheduleWalletCheck(state: &state, clock: clock)
                }
                return .none
            case .onDisappear:
                state.isVisible = false
                return .none
            case let .scenePhaseChanged(newPhase):
                if newPhase == .active && state.shouldHandleScenePhaseChange {
                    return scheduleWalletCheck(state: &state, clock: clock)
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
            switch Splash.newUserRoute(hasCompletedInitialRoute: state.hasCompletedInitialRoute) {
            case .alreadyOnWelcome:
                // A second check still sees no wallet on a fresh install. Welcome is
                // already on screen; that is not "Wallet initialisation failed".
                return .none
            case .openWelcome:
                return .send(.delegate(.handleNewUser))
            }
        }
    }

    private func scheduleWalletCheck(
        state: inout State,
        clock: any Clock<Duration>
    ) -> Effect<Action> {
        guard !state.walletCheckPending else { return .none }
        state.walletCheckPending = true
        return .run { send in
            /// We need to fetch data from keychain, in order to be 100% sure the keychain can be read we delay the check a bit
            try await clock.sleep(for: .seconds(0.5))
            await send(.checkWalletInitialization)
        }
    }

    public init() {}
}

public extension Splash {
    /// Where a `.newUser` splash result should go.
    ///
    /// Cold start runs the wallet check twice (`onAppear` and the scene becoming
    /// active). The first check opens welcome and sets `hasCompletedInitialRoute`.
    /// The second check still sees an empty keychain. That is welcome, not a
    /// failed initialisation.
    enum NewUserRoute: Equatable {
        case openWelcome
        case alreadyOnWelcome
    }

    static func newUserRoute(hasCompletedInitialRoute: Bool) -> NewUserRoute {
        hasCompletedInitialRoute ? .alreadyOnWelcome : .openWelcome
    }

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
