//
//  Splash.swift
//

import AppVersion
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
        public var hasAttemptedAuthentication = false
        public var initializationState = InitializationState.uninitialized
        public var isAuthenticating = false
        public var lastAuthenticatedTime: Date?
        public var lastInactiveTime: Date?
        public var phase = ScenePhase.background
        public var isVisible = true
        /// Status line under the logo (Tor bootstrap, matching Android splash).
        public var statusMessage: String?
        /// Show “Continue without Tor” while bootstrap is in progress or failed.
        public var showDisableTorButton = false
        /// `vX.Y.Z` footer (Android `splash_app_version` parity).
        public var appVersion: String = ""
        public var walletCheckComplete = false
        public var torGateOpen = false
        public var didDispatchRoute = false
        public var didStartLaunch = false
        /// Once the user has been routed past splash, avoid sending them back to welcome
        /// when splash reappears after background lock / scene phase changes.
        public var hasCompletedInitialRoute = false
        public var shouldHandleScenePhaseChange: Bool {
            isVisible && !isAuthenticating && !hasAttemptedAuthentication
        }

        public init() {}

        public mutating func resetForRelock() {
            lastAuthenticatedTime = nil
            hasAttemptedAuthentication = false
            isAuthenticating = false
            walletCheckComplete = false
            torGateOpen = false
            didDispatchRoute = false
            didStartLaunch = false
            statusMessage = nil
            showDisableTorButton = false
        }
    }

    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case authenticate
        case authenticationResponse(Bool)
        case checkWalletInitialization
        case bootstrapTorThenLaunch
        case torBootstrapSucceeded
        case torBootstrapFailed
        case disableTorAndContinue
        case delegate(Delegate)
        case onDisappear
        case onAppear
        case retryTapped
        case scenePhaseChanged(ScenePhase)

        public enum Alert: Equatable {}

        public enum Delegate: Equatable {
            case handleNewUser
            case handleMigration
            case handleNeedsBackup
            case handlePostBackupOnboarding
            case initializeSDKAndLaunchWallet
        }
    }

    private enum CancelID { case torBootstrap }

    @Dependency(\.appVersion) var appVersion
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.torBootstrap) var torBootstrap
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
                    } else {
                        await send(.authenticationResponse(false))
                    }
                }
            case let .authenticationResponse(authenticated):
                state.hasAttemptedAuthentication = true
                state.isAuthenticating = false
                if authenticated {
                    state.lastAuthenticatedTime = date()
                    return continueAfterGates(state: &state)
                }
                return .none
            case .bootstrapTorThenLaunch:
                return startTorBootstrap(state: &state)
            case .torBootstrapSucceeded:
                state.statusMessage = L10n.Nighthawk.Splash.torReady
                state.showDisableTorButton = false
                state.torGateOpen = true
                return continueAfterGates(state: &state)
            case .torBootstrapFailed:
                state.statusMessage = L10n.Nighthawk.Splash.torFailed
                state.showDisableTorButton = true
                return .none
            case .disableTorAndContinue:
                userStoredPreferences.setTorForWalletEnabled(false)
                userStoredPreferences.setTorForChatEnabled(false)
                torBootstrap.stop()
                state.statusMessage = nil
                state.showDisableTorButton = false
                state.torGateOpen = true
                return .merge(
                    .cancel(id: CancelID.torBootstrap),
                    continueAfterGates(state: &state)
                )
            case .checkWalletInitialization:
                state.initializationState = Splash.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    darkfiNetwork: DarkFiNetworkLabel.current
                )
                state.walletCheckComplete = true

                switch state.initializationState {
                case .failed:
                    state.alert = AlertState.walletStateFailed(state.initializationState)
                    return .none
                case .keysMissing:
                    state.alert = AlertState.walletStateFailed(state.initializationState)
                    return .none
                case .needsMigration, .initialized, .filesMissing, .uninitialized:
                    return continueAfterGates(state: &state)
                }
            case .delegate:
                return .none
            case .onAppear:
                state.isVisible = true
                if state.appVersion.isEmpty {
                    state.appVersion = appVersion.appVersion()
                }
                guard !state.didStartLaunch else {
                    return .none
                }
                state.didStartLaunch = true
                return startLaunch(state: &state)
            case .onDisappear:
                state.isVisible = false
                return .none
            case let .scenePhaseChanged(newPhase):
                if newPhase == .active && state.shouldHandleScenePhaseChange && !state.didStartLaunch {
                    state.didStartLaunch = true
                    if state.appVersion.isEmpty {
                        state.appVersion = appVersion.appVersion()
                    }
                    return startLaunch(state: &state)
                }
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    public init() {}
}

// MARK: - Launch gates (Android splash parity)
private extension Splash {
    func startLaunch(state: inout State) -> Effect<Action> {
        let torOn = userStoredPreferences.torForWalletEnabled()
            || userStoredPreferences.torForChatEnabled()
        let walletCheck = Effect<Action>.run { send in
            /// Keychain can lag on first process start; delay matches the historic splash path.
            try await clock.sleep(for: .seconds(0.5))
            await send(.checkWalletInitialization)
        }
        if torOn {
            return .merge(startTorBootstrap(state: &state), walletCheck)
        }
        state.statusMessage = nil
        state.showDisableTorButton = false
        state.torGateOpen = true
        return walletCheck
    }

    func startTorBootstrap(state: inout State) -> Effect<Action> {
        let socksPort = UInt16(userStoredPreferences.torSocksPort() ?? "9050") ?? 9050
        state.statusMessage = L10n.Nighthawk.Splash.torBootstrapping
        state.showDisableTorButton = true
        state.torGateOpen = false
        return .run { [torBootstrap] send in
            let ready = await torBootstrap.ensureReady(socksPort)
            if ready {
                await send(.torBootstrapSucceeded)
            } else {
                await send(.torBootstrapFailed)
            }
        }
        .cancellable(id: CancelID.torBootstrap, cancelInFlight: true)
    }

    func continueAfterGates(state: inout State) -> Effect<Action> {
        guard !state.didDispatchRoute, state.walletCheckComplete else {
            return .none
        }

        switch state.initializationState {
        case .failed, .keysMissing:
            return .none
        case .needsMigration:
            guard state.torGateOpen else { return .none }
            state.didDispatchRoute = true
            return .send(.delegate(.handleMigration))
        case .initialized, .filesMissing:
            if !userStoredPreferences.isUserBackupComplete() {
                guard state.torGateOpen else { return .none }
                state.didDispatchRoute = true
                return .send(.delegate(.handleNeedsBackup))
            }
            // First-time: seed is backed up but the educational carousel has not run.
            // Existing installs already have wallet DB files and never stored this flag.
            if !userStoredPreferences.hasCompletedOnboarding()
                && !databaseFiles.areDbFilesPresentFor("testnet") {
                guard state.torGateOpen else { return .none }
                state.didDispatchRoute = true
                return .send(.delegate(.handlePostBackupOnboarding))
            }
            if userStoredPreferences.areBiometricsEnabled() && !state.authenticated {
                return .send(.authenticate)
            }
            guard state.torGateOpen else { return .none }
            state.didDispatchRoute = true
            return .send(.delegate(.initializeSDKAndLaunchWallet))
        case .uninitialized:
            guard !state.hasCompletedInitialRoute else {
                state.alert = AlertState.walletStateFailed(.uninitialized)
                return .none
            }
            guard state.torGateOpen else { return .none }
            state.didDispatchRoute = true
            return .send(.delegate(.handleNewUser))
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
