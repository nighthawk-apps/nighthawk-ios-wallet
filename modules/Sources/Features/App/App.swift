//
//  App.swift
//
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import DatabaseFiles
import DerivationTool
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
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct AppReducer: Reducer {
    let zcashNetwork: ZcashNetwork
    
    enum CancelId { case timer }
    
    public struct State: Equatable {
        @PresentationState public var destination: Destination.State?
        public var path = StackState<Path.State>()
        public var splash = Splash.State()
        public var synchronizerStopped = false
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case initializeSDKFailed(ZcashError)
        case initializeSDKSuccess(shouldResetStack: Bool)
        case nukeWalletSuccess
        case nukeWalletFailed
        case path(StackAction<Path.State, Path.Action>)
        case scenePhaseChanged(ScenePhase)
        case splash(Splash.Action)
    }
    
    public struct Path: Reducer {
        let zcashNetwork: ZcashNetwork
        
        public enum State: Equatable {
            case about(About.State = .init())
            case advanced(Advanced.State = .init())
            case backup(RecoveryPhraseDisplay.State)
            case changeServer(ChangeServer.State = .init())
            case externalServices(ExternalServices.State = .init())
            case fiat(Fiat.State = .init())
            case home(Home.State = .init())
            case importWallet(ImportWallet.State = .init())
            case importWalletSuccess(ImportWalletSuccess.State = .init())
            case licenses
            case migrate(Migrate.State = .init())
            case notifications(Notifications.State = .init())
            case recoveryPhraseDisplay(RecoveryPhraseDisplay.State)
            case security(Security.State = .init())
            case transactionDetail(TransactionDetail.State)
            case transactionHistory(TransactionHistory.State = .init())
            case walletCreated(WalletCreated.State = .init())
            case welcome(Welcome.State = .init())
        }
        
        public enum Action: Equatable {
            case about(About.Action)
            case advanced(Advanced.Action)
            case backup(RecoveryPhraseDisplay.Action)
            case changeServer(ChangeServer.Action)
            case externalServices(ExternalServices.Action)
            case fiat(Fiat.Action)
            case home(Home.Action)
            case importWallet(ImportWallet.Action)
            case importWalletSuccess(ImportWalletSuccess.Action)
            case licenses(Never)
            case migrate(Migrate.Action)
            case notifications(Notifications.Action)
            case recoveryPhraseDisplay(RecoveryPhraseDisplay.Action)
            case security(Security.Action)
            case transactionDetail(TransactionDetail.Action)
            case transactionHistory(TransactionHistory.Action)
            case walletCreated(WalletCreated.Action)
            case welcome(Welcome.Action)
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.about, action: /Action.about) {
                About()
            }
            
            Scope(state: /State.advanced, action: /Action.advanced) {
                Advanced()
            }
            
            Scope(state: /State.backup, action: /Action.backup) {
                RecoveryPhraseDisplay(zcashNetwork: zcashNetwork)
            }
            
            Scope(state: /State.changeServer, action: /Action.changeServer) {
                ChangeServer()
            }
            
            Scope(state: /State.externalServices, action: /Action.externalServices) {
                ExternalServices()
            }
            
            Scope(state: /State.fiat, action: /Action.fiat) {
                Fiat()
            }
            
            Scope(state: /State.home, action: /Action.home) {
                Home(zcashNetwork: zcashNetwork)
            }
            
            Scope(state: /State.importWallet, action: /Action.importWallet) {
                ImportWallet(saplingActivationHeight: zcashNetwork.constants.saplingActivationHeight)
            }
            
            Scope(state: /State.importWalletSuccess, action: /Action.importWalletSuccess) {
                ImportWalletSuccess()
            }
            
            Scope(state: /State.migrate, action: /Action.migrate) {
                Migrate()
            }
            
            Scope(state: /State.notifications, action: /Action.notifications) {
                Notifications()
            }
            
            Scope(state: /State.recoveryPhraseDisplay, action: /Action.recoveryPhraseDisplay) {
                RecoveryPhraseDisplay(zcashNetwork: zcashNetwork)
            }
            
            Scope(state: /State.security, action: /Action.security) {
                Security()
            }
            
            Scope(state: /State.transactionDetail, action: /Action.transactionDetail) {
                TransactionDetail()
            }
            
            Scope(state: /State.transactionHistory, action: /Action.transactionHistory) {
                TransactionHistory()
            }
            
            Scope(state: /State.walletCreated, action: /Action.walletCreated) {
                WalletCreated()
            }
            
            Scope(state: /State.welcome, action: /Action.welcome) {
                Welcome()
            }
        }
        
        public init(zcashNetwork: ZcashNetwork) {
            self.zcashNetwork = zcashNetwork
        }
    }
    
    public struct Destination: Reducer {
        public enum State: Equatable {
            case alert(AlertState<Action.Alert>)
        }
        
        public enum Action: Equatable {
            case alert(Alert)
            
            public enum Alert: Equatable {}
        }
        
        public var body: some ReducerOf<Self> {
            Reduce { _, _ in .none }
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.date) var date
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: /Action.splash) {
            Splash(zcashNetwork: zcashNetwork)
        }
        
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case let .initializeSDKFailed(error):
                state.destination = .alert(.sdkInitFailed(error))
                return .none
            case let .initializeSDKSuccess(shouldResetStack: shouldResetStack):
                state.synchronizerStopped = false
                if shouldResetStack {
                    state.path = StackState([.home()])
                }
                return .none
            case .nukeWalletFailed:
                return .none
            case .nukeWalletSuccess:
                walletStorage.nukeWallet()
                try? databaseFiles.nukeDbFilesFor(zcashNetwork)
                state.path = StackState([.welcome(.init())])
                return .none
            case .path:
                return .none
            case let .scenePhaseChanged(newPhase):
                defer { state.splash.phase = newPhase }
                switch newPhase {
                case .inactive:
                    state.synchronizerStopped = true
                    sdkSynchronizer.stop()
                    return .none
                case .active:
                    defer { state.splash.lastInactiveTime = nil }
                    if state.shouldResetToSplash {
                        state.splash.lastAuthenticatedTime = nil
                        state.splash.hasAttemptedAuthentication = false
                        state.splash.isAuthenticating = false
                        state.path = StackState()
                    } else if !state.path.isEmpty && state.synchronizerStopped {
                        return initializeSDK(.existingWallet, shouldResetStack: false)
                    }
                    return .none
                case .background:
                    state.splash.lastInactiveTime = date()
                    return .none
                @unknown default:
                    return .none
                }
            case .splash:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
        .forEach(\.path, action: /Action.path) {
            Path(zcashNetwork: zcashNetwork)
        }
        
        splashDelegateReducer()
        onboardingReducer()
        walletReducer()
        transferReducer()
        settingsReducer()
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }
}

// MARK: - Initialize SDK
extension AppReducer {
    func initializeSDK(_ mode: WalletInitMode, shouldResetStack: Bool = true) -> Effect<Action> {
        do {
            // Retrieve wallet
            let storedWallet = try walletStorage.exportWallet()
            let birthday = storedWallet.birthday?.value() ?? zcashSDKEnvironment.latestCheckpoint(zcashNetwork)
            
            try mnemonic.isValid(storedWallet.seedPhrase.value())
            let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
            
            return .run { send in
                do {
                    // Prepare, if needed
                    if !sdkSynchronizer.isInitialized() {
                        try await sdkSynchronizer.prepareWith(seedBytes, birthday, mode)
                    }
                    
                    // Start synchronizer
                    try await sdkSynchronizer.start(false)
                    await send(.initializeSDKSuccess(shouldResetStack: shouldResetStack))
                } catch {
                    await send(.initializeSDKFailed(error.toZcashError()))
                }
            }
        } catch {
            return .send(.initializeSDKFailed(error.toZcashError()))
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
                    state.path.append(.welcome())
                    return .none
                case .handleMigration:
                    state.path.append(.migrate())
                    return .none
                case .initializeSDKAndLaunchWallet:
                    return initializeSDK(.existingWallet)
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .scenePhaseChanged, .splash:
                return .none
            }
        }
    }
}

private extension AppReducer.State {
    var shouldResetToSplash: Bool {
        @Dependency(\.userStoredPreferences) var userStoredPreferences
        guard !path.isEmpty, userStoredPreferences.areBiometricsEnabled(), splash.lastInactiveTime != nil else { return false }
        
        // Don't reset if user was inactive less than 10 minutes
        @Dependency(\.date) var date
        if let lastInactiveTime = splash.lastInactiveTime {
            let tenMinutesAgo = date().addingTimeInterval(-(10 * 60))
            if tenMinutesAgo < lastInactiveTime {
                return false
            }
        }
        
        // Reset to splash
        // Any system prompt causes a scene phase change to .inactive,
        // so don't stop synchronizer if the app is on screens where that happens:
        // - Security screen (Face ID enable / disable)
        // - Notification screen (system permission alert)
        // - Transfer tab (send flow pasteboard permission alert)
        
        if let currentScreen = path.last {
            if let home = (/AppReducer.Path.State.home).extract(from: currentScreen) {
                return home.selectedTab != .transfer
            }
            
            if let _ = (/AppReducer.Path.State.security).extract(from: currentScreen) {
                return false
            }
            
            if let _ = (/AppReducer.Path.State.notifications).extract(from: currentScreen) {
                return false
            }
        }
        
        return true
    }
}
