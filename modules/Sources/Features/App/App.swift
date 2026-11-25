//
//  App.swift
//
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import DarkfiCore
import Utils
import DatabaseFiles
import DerivationTool
import FileManager
import Generated
import Home
import ImportWallet
import ImportWalletSuccess
import Migrate
import MnemonicClient
import Models
import RecoveryPhraseDisplay
import SDKSynchronizer
import Splash
import SwiftUI
import TransactionDetail
import UserPreferencesStorage
import WalletCreated
import WalletStorage
import Welcome

@Reducer
public struct AppReducer {
    enum CancelId { case timer }

    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var path = StackState<Path.State>()
        public var splash = Splash.State()
        public var synchronizerStopped = false
        public var receiveAddress: DarkfiAddress?
        public var latestFiatPrice: Double?
        public var nighthawkColorScheme: ColorScheme? {
            NighthawkThemeController.currentTheme.colorScheme
        }

        var isWelcomeScreenShown: Bool {
            if let currentScreen = path.last {
                return currentScreen[case: \.welcome] != nil
            }

            return false
        }

        public init() {}

        /// Keep App and the live Home wallet info on the same address so
        /// transaction history can load after the address arrives.
        mutating func propagateDarkfiAddress(_ receiveAddress: DarkfiAddress) {
            self.receiveAddress = receiveAddress
            for id in path.ids {
                guard let home = path[id: id, case: \.home] else { continue }
                home.$walletInfo.withLock { $0.receiveAddress = receiveAddress }
                path[id: id, case: \.home] = home
            }
        }
    }

    public enum Action {
        case alert(PresentationAction<Alert>)
        case createWalletFailed(DarkFiError)
        case createWalletSucceeded
        case initializeSDKFailed(DarkFiError)
        case initializeSDKSuccess(shouldResetStack: Bool)
        case deleteWalletSuccess
        case deleteWalletFailed
        case nukeLocalDatabasesSuccess
        case nukeLocalDatabasesFailed
        case path(StackActionOf<Path>)
        case scenePhaseChanged(ScenePhase)
        case splash(Splash.Action)
        case receiveAddressResponse(DarkfiAddress?)

        public enum Alert: Equatable {}
    }

    @Reducer
    public enum Path {
        case about(About)
        case advanced(Advanced)
        case backup(RecoveryPhraseDisplay)
        case chatSettings(ChatSettings)
        case changeServer(ChangeServer)
        case daoHub(DaoHub)
        case fiat(Fiat)
        case home(Home)
        case importWallet(ImportWallet)
        case importWalletSuccess(ImportWalletSuccess)
        case migrate(Migrate)
        case notifications(Notifications)
        case recoveryPhraseDisplay(RecoveryPhraseDisplay)
        case security(Security)
        case torNetwork(TorNetwork)
        case transactionDetail(TransactionDetail)
        case transactionHistory(TransactionHistory)
        case walletCreated(WalletCreated)
        case welcome(Welcome)
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.date) var date
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.fileManager) var fileManager
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage

    public var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) {
            Splash()
        }

        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case let .createWalletFailed(error):
                state.alert = .cantCreateNewWallet(error)
                return .none
            case .createWalletSucceeded:
                state.path = StackState([
                    .recoveryPhraseDisplay(.init(flow: .onboarding))
                ])
                return .none
            case let .initializeSDKFailed(error):
                // Fail closed on UX: surface the error. Still open home so chat/settings
                // remain reachable while the synchronizer stays stopped.
                state.alert = .sdkInitFailed(error)
                state.synchronizerStopped = true
                state.splash.hasCompletedInitialRoute = true
                state.path = StackState([
                    .home(
                        .init(receiveAddress: nil)
                    )
                ])
                return .none
            case let .initializeSDKSuccess(shouldResetStack: shouldResetStack):
                state.synchronizerStopped = false
                state.splash.hasCompletedInitialRoute = true
                if shouldResetStack {
                    state.path = StackState([
                        .home(
                            .init(receiveAddress: state.receiveAddress)
                        )
                    ])
                }
                return .none
            case .deleteWalletFailed:
                return .none
            case .deleteWalletSuccess:
                DarkircDaemonManager.shared.stop()
                walletStorage.deleteWallet()
                SecurityPinStore.clearPin()
                userStoredPreferences.removeAll()
                NighthawkContactStore.removeAll()
                DeviceAddressBook.removeAll()
                DarkfiChatDefaults.resetNickname()
                ChatReceiptBook.clearAll()
                ChatHistoryStore.clearAll()
                let fileMgr = Foundation.FileManager.default
                if let docs = fileMgr.urls(for: .documentDirectory, in: .userDomainMask).first {
                    try? fileMgr.removeItem(at: docs.appendingPathComponent("darkirc_db", isDirectory: true))
                }
                if let appSupport = fileMgr.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                    try? fileMgr.removeItem(at: appSupport.appendingPathComponent("nighthawk-chat", isDirectory: true))
                    try? fileMgr.removeItem(at: appSupport.appendingPathComponent("darkirc", isDirectory: true))
                }
                state.receiveAddress = nil
                state.latestFiatPrice = nil
                state.splash.hasCompletedInitialRoute = false
                if let eventsCache = URL.latestEventsCache(for: DarkfiNetwork.activeLabel) {
                    try? fileManager.removeItem(eventsCache)
                }

                state.path = StackState([.welcome(.init())])
                return .run { _ in
                    await MainActor.run {
                        NighthawkMeshController.shared.wipe()
                    }
                    await DarkircCryptoStore.shared.clearAll()
                    await ChatOutboxStore.shared.clearAll()
                    for _ in 0..<20 {
                        let status = darkircStatus()
                        if status == "not_running" || status == "stopped" || status == "failed" {
                            break
                        }
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                    let fileMgr = Foundation.FileManager.default
                    if let docs = fileMgr.urls(for: .documentDirectory, in: .userDomainMask).first {
                        try? fileMgr.removeItem(at: docs.appendingPathComponent("darkirc_db", isDirectory: true))
                    }
                }
            case .nukeLocalDatabasesFailed:
                state.alert = .nukeLocalDatabasesFailed()
                return .none
            case .nukeLocalDatabasesSuccess:
                state.alert = .nukeLocalDatabasesSucceeded()
                state.synchronizerStopped = true
                // Re-open wallet from seed against fresh DBs (same as splash path).
                return initializeSDK(.existingWallet, shouldResetStack: false)
            case .path:
                return .none
            case let .scenePhaseChanged(newPhase):
                defer { state.splash.phase = newPhase }
                switch newPhase {
                case .inactive:
                    // System prompts (Face ID, pasteboard, notifications) briefly
                    // flip to .inactive — keep syncing through those.
                    return .none
                case .active:
                    defer { state.splash.lastInactiveTime = nil }
                    if shouldResetToSplash(
                        state,
                        authLockEnabled: userStoredPreferences.areBiometricsEnabled() || SecurityPinStore.isPinSet(),
                        now: date()
                    ) {
                        state.splash.lastAuthenticatedTime = nil
                        state.splash.hasAttemptedAuthentication = false
                        state.splash.isAuthenticating = false
                        state.splash.requiresPinEntry = false
                        state.splash.pinInput = ""
                        state.splash.pinError = nil
                        state.path = StackState()
                    } else if !state.path.isEmpty && state.synchronizerStopped && !state.isWelcomeScreenShown {
                        return initializeSDK(.existingWallet, shouldResetStack: false)
                    }
                    return .none
                case .background:
                    state.splash.lastInactiveTime = date()
                    state.synchronizerStopped = true
                    sdkSynchronizer.stop()
                    return .none
                @unknown default:
                    return .none
                }
            case .splash:
                return .none
            case let .receiveAddressResponse(receiveAddress):
                if let receiveAddress {
                    state.propagateDarkfiAddress(receiveAddress)
                }
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .forEach(\.path, action: \.path)

        splashDelegateReducer()
        onboardingReducer()
        homeDelegateReducer()
        walletReducer()
        transferReducer()
        settingsReducer()
    }

    public init() {}
}

extension AppReducer.Path.State: Equatable {}
extension AppReducer.Path.Action: Equatable {}

// MARK: - Initialize SDK
extension AppReducer {
    func initializeSDK(_ mode: WalletInitMode, shouldResetStack: Bool = true) -> Effect<Action> {
        do {
            if mode == .newWallet && !userStoredPreferences.isUserBackupComplete() {
                return .none
            }
            // Retrieve wallet
            let storedWallet = try walletStorage.exportWallet()
            // DarkFi: no checkpoint concept
            let birthday = storedWallet.birthday?.value() ?? 0
            // DarkFi wallet keys derive from the UTF-8 mnemonic phrase (not BIP-39 seed bytes).
            let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())

            return .run { send in
                do {
                    // Prepare and start
                    try await sdkSynchronizer.prepareWith(seedBytes, birthday, mode)

                    // Get address. Do not write the plaintext address into Documents.
                    let address = try? await sdkSynchronizer.getAddress()
                    await send(.receiveAddressResponse(address))
                    try await sdkSynchronizer.start(false)
                    await send(.initializeSDKSuccess(shouldResetStack: shouldResetStack))
                } catch {
                    await send(.initializeSDKFailed(error.toDarkFiError()))
                }
            }
        } catch {
            return .send(.initializeSDKFailed(error.toDarkFiError()))
        }
    }
}

// MARK: - Splash delegate
private extension AppReducer {
    func splashDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .splash(.delegate(action)):
                switch action {
                case .handleNewUser:
                    state.splash.hasCompletedInitialRoute = true
                    state.path.append(.welcome(.init()))
                    return .none
                case .handleMigration:
                    state.splash.hasCompletedInitialRoute = true
                    state.path.append(.migrate(.init()))
                    return .none
                case .handleNeedsBackup:
                    state.splash.hasCompletedInitialRoute = true
                    state.path = StackState([
                        .recoveryPhraseDisplay(.init(flow: .onboarding))
                    ])
                    return .none
                case .initializeSDKAndLaunchWallet:
                    state.splash.hasCompletedInitialRoute = true
                    return initializeSDK(.existingWallet)
                }
            case .alert, .createWalletFailed, .createWalletSucceeded, .initializeSDKFailed, .initializeSDKSuccess,
                .deleteWalletFailed, .deleteWalletSuccess, .nukeLocalDatabasesFailed, .nukeLocalDatabasesSuccess,
                .path, .scenePhaseChanged, .splash, .receiveAddressResponse:
                return .none
            }
        }
    }
}

/// Biometrics or PIN lock after 10 minutes away. Preferences and the clock are read here, not on `State`.
private func shouldResetToSplash(
    _ state: AppReducer.State,
    authLockEnabled: Bool,
    now: Date
) -> Bool {
    guard !state.path.isEmpty, authLockEnabled, state.splash.lastInactiveTime != nil else { return false }

    if let lastInactiveTime = state.splash.lastInactiveTime {
        let tenMinutesAgo = now.addingTimeInterval(-(10 * 60))
        if tenMinutesAgo < lastInactiveTime {
            return false
        }
    }

    return true
}
