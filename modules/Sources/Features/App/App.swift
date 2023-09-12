//
//  App.swift
//  
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import DerivationTool
import Generated
import Home
import MnemonicClient
import Models
import RecoveryPhraseDisplay
import SDKSynchronizer
import Splash
import WalletCreated
import WalletStorage
import Welcome
import ZcashLightClientKit
import ZcashSDKEnvironment

public struct AppReducer: ReducerProtocol {
    let zcashNetwork: ZcashNetwork
    
    public struct State: Equatable {
        @PresentationState public var destination: Destination.State?
        public var path = StackState<Path.State>()
        public var splash = Splash.State()
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case initializeSDKFailed(ZcashError)
        case initializeSDKSuccess
        case path(StackAction<Path.State, Path.Action>)
        case splash(Splash.Action)
    }
    
    public struct Path: ReducerProtocol {
        let zcashNetwork: ZcashNetwork
        
        public enum State: Equatable {
            case home(Home.State)
            case recoveryPhraseDisplay(RecoveryPhraseDisplay.State)
            case walletCreated(WalletCreated.State)
            case welcome(Welcome.State)
        }
        
        public enum Action: Equatable {
            case home(Home.Action)
            case recoveryPhraseDisplay(RecoveryPhraseDisplay.Action)
            case walletCreated(WalletCreated.Action)
            case welcome(Welcome.Action)
        }
        
        public var body: some ReducerProtocolOf<Self> {
            Scope(state: /State.home, action: /Action.home) {
                Home(zcashNetwork: zcashNetwork)
            }
            
            Scope(state: /State.recoveryPhraseDisplay, action: /Action.recoveryPhraseDisplay) {
                RecoveryPhraseDisplay()
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
    
    public struct Destination: ReducerProtocol {
        public enum State: Equatable {
            case alert(AlertState<Action.Alert>)
        }
        
        public enum Action: Equatable {
            case alert(Alert)
            
            public enum Alert: Equatable {}
        }
        
        public var body: some ReducerProtocolOf<Self> {
            Reduce { _, _ in .none }
        }
    }
    
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerProtocolOf<Self> {
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
            case .initializeSDKSuccess:
                state.path.append(.home(Home.State.placeholder))
                return .none
            case .path:
                return .none
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
        
        welcomeDelegateReducer()
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }
}

// MARK: - Alerts
extension AlertState where Action == AppReducer.Destination.Action.Alert {
    public static func cantCreateNewWallet(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.Welcome.Initialization.Alert.Failed.title)
        } message: {
            TextState(L10n.Nighthawk.Welcome.Initialization.Alert.CantCreateNewWallet.message(error.message, error.code.rawValue))
        }
    }
    
    public static func sdkInitFailed(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.App.Launch.Alert.SdkInitFailed.title)
        } message: {
            TextState(L10n.Nighthawk.App.Launch.Alert.Error.message(error.message, error.code.rawValue))
        }
    }
}

// MARK: - Initialize SDK
private extension AppReducer {
    func initializeSDK() -> EffectTask<Action> {
        do {
            // Retrieve wallet
            let storedWallet = try walletStorage.exportWallet()
            let birthday = storedWallet.birthday?.value() ?? zcashSDKEnvironment.latestCheckpoint(zcashNetwork)

            try mnemonic.isValid(storedWallet.seedPhrase.value())
            let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())

            return .run { send in
                do {
                    // Start synchronizer
                    try await sdkSynchronizer.prepareWith(seedBytes, birthday, .existingWallet)
                    try await sdkSynchronizer.start(false)
                    await send(.initializeSDKSuccess)
                } catch {
                    await send(.initializeSDKFailed(error.toZcashError()))
                }
            }
        } catch {
            return EffectTask(value: .initializeSDKFailed(error.toZcashError()))
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
                    return .none
                case .initializeSDKAndLaunchWallet:
                    return initializeSDK()
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .path, .splash:
                return .none
            }
        }
    }
}

// MARK: - Welcome delegate
private extension AppReducer {
    func welcomeDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .welcome(.delegate(delegateAction)))):
                switch delegateAction {
                case .createNewWallet:
                    do {
                        // get the random english mnemonic
                        let newRandomPhrase = try mnemonic.randomMnemonic()
                        let birthday = zcashSDKEnvironment.latestCheckpoint(zcashNetwork)

                        // store the wallet to the keychain
                        try walletStorage.importWallet(newRandomPhrase, birthday, .english)

                        // Show the backup phrase
                        let randomRecoveryPhraseWords = mnemonic.asWords(newRandomPhrase)
                        let recoveryPhrase = RecoveryPhrase(words: randomRecoveryPhraseWords.map { $0.redacted })
                        
                        state.path.append(
                            .recoveryPhraseDisplay(
                                .init(
                                    flow: .onboarding,
                                    phrase: recoveryPhrase,
                                    birthday: birthday
                                )
                            )
                        )

                        return .none
                    } catch {
                        state.destination = .alert(.cantCreateNewWallet(error.toZcashError()))
                    }
                    return .none
                case .importExistingWallet:
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .path, .splash:
                return .none
            }
        }
    }
}

