//
//  App.swift
//
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
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
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct AppReducer {
    enum CancelId { case timer }
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var path = StackState<Path.State>()
        public var splash = Splash.State()
        public var synchronizerStopped = false
        public var unifiedAddress: UnifiedAddress?
        public var latestFiatPrice: Double?
        public var nighthawkColorScheme: ColorScheme {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return if userStoredPreferences.isBandit() {
                userStoredPreferences.theme().colorScheme
            } else {
                .light
            }
        }
        
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
                if let home = currentScreen[case: \.home] {
                    return home.selectedTab != .transfer
                }
                
                if let _ = currentScreen[case: \.security] {
                    return false
                }
                
                if let _ = currentScreen[case: \.notifications] {
                    return false
                }
            }
            
            return true
        }
        
        var isWelcomeScreenShown: Bool {
            if let currentScreen = path.last {
                return currentScreen[case: \.welcome] != nil
            }
            
            return false
        }
        
        public init() {}
    }
    
    public enum Action {
        case alert(PresentationAction<Alert>)
        case initializeSDKFailed(ZcashError)
        case initializeSDKSuccess(shouldResetStack: Bool)
        case deleteWalletSuccess
        case deleteWalletFailed
        case path(StackAction<Path.State, Path.Action>)
        case scenePhaseChanged(ScenePhase)
        case splash(Splash.Action)
        case unifiedAddressResponse(UnifiedAddress?)
        
        public enum Alert: Equatable {}
    }
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Path {
        case about(About)
        case advanced(Advanced)
        case backup(RecoveryPhraseDisplay)
        case changeServer(ChangeServer)
        case externalServices(ExternalServices)
        case fiat(Fiat)
        case home(Home)
        case importWallet(ImportWallet)
        case importWalletSuccess(ImportWalletSuccess)
        case migrate(Migrate)
        case notifications(Notifications)
        case recoveryPhraseDisplay(RecoveryPhraseDisplay)
        case security(Security)
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
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) {
            Splash()
        }
        
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case let .initializeSDKFailed(error):
                state.alert = .sdkInitFailed(error)
                return .none
            case let .initializeSDKSuccess(shouldResetStack: shouldResetStack):
                state.synchronizerStopped = false
                if shouldResetStack {
                    state.path = StackState([
                        .home(
                            .init(unifiedAddress: state.unifiedAddress)
                        )
                    ])
                }
                return .none
            case .deleteWalletFailed:
                return .none
            case .deleteWalletSuccess:
                walletStorage.deleteWallet()
                userStoredPreferences.removeAll()
                state.unifiedAddress = nil
                state.latestFiatPrice = nil
                if let eventsCache = URL.latestEventsCache(for: zcashSDKEnvironment.network.networkType) {
                    try? fileManager.removeItem(eventsCache)
                }
                
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
                    } else if !state.path.isEmpty && state.synchronizerStopped && !state.isWelcomeScreenShown {
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
            case let .unifiedAddressResponse(unifiedAddress):
                if let unifiedAddress {
                    state.unifiedAddress = unifiedAddress
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

// MARK: - Initialize SDK
extension AppReducer {
    func initializeSDK(_ mode: WalletInitMode, shouldResetStack: Bool = true) -> Effect<Action> {
        do {
            // Retrieve wallet
            let storedWallet = try walletStorage.exportWallet()
            let birthday = storedWallet.birthday?.value() ?? zcashSDKEnvironment.latestCheckpoint
            let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
            
            return .run { send in
                do {
                    // Prepare, if needed
                    if !sdkSynchronizer.isInitialized() {
                        try await sdkSynchronizer.prepareWith(seedBytes, birthday, mode)
                    }
                    
                    // Start synchronizer
                    let ua = try? await sdkSynchronizer.getUnifiedAddress(0)
                    await send(.unifiedAddressResponse(ua))
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
                    state.path.append(.welcome(.init()))
                    return .none
                case .handleMigration:
                    state.path.append(.migrate(.init()))
                    return .none
                case .initializeSDKAndLaunchWallet:
                    return initializeSDK(.existingWallet)
                }
            case .alert, .initializeSDKFailed, .initializeSDKSuccess, .deleteWalletFailed, .deleteWalletSuccess, .path, .scenePhaseChanged, .splash, .unifiedAddressResponse:
                return .none
            }
        }
    }
}
