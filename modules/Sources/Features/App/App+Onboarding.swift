//
//  App+Onboarding.swift
//  
//
//  Created by Matthew Watt on 9/12/23.
//

import ComposableArchitecture
import Models

extension AppReducer {
    @ReducerBuilder<State, Action>
    func onboardingReducer() -> some ReducerProtocolOf<Self> {
        welcomeDelegateReducer()
        importWalletDelegateReducer()
        importWalletSuccessDelegateReducer()
        migrateDelegateReducer()
        walletCreatedDelegateReducer()
        recoveryPhraseDisplayDelegateReducer()
    }
    
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
                        
                        state.path.append(.walletCreated())
                        return .none
                    } catch {
                        state.destination = .alert(.cantCreateNewWallet(error.toZcashError()))
                    }
                    return .none
                case .importExistingWallet:
                    state.path.append(.importWallet())
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .splash:
                return .none
            }
        }
    }
    
    func importWalletDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .importWallet(.delegate(delegateAction)))):
                switch delegateAction {
                case .showImportSuccess:
                    state.path.append(.importWalletSuccess())
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .splash:
                return .none
            }
        }
    }
    
    func importWalletSuccessDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .importWalletSuccess(.delegate(delegateAction)))):
                switch delegateAction {
                case .initializeSDKAndLaunchWallet:
                    return initializeSDK()
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .splash:
                return .none
            }
        }
    }
    
    func migrateDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .migrate(.delegate(delegateAction)))):
                switch delegateAction {
                case .initializeSDKAndLaunchWallet:
                    return initializeSDK()
                case .importManually:
                    state.path = StackState([.welcome()])
                    return .none
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .splash:
                return .none
            }
        }
    }
    
    func walletCreatedDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .walletCreated(.delegate(delegateAction)))):
                switch delegateAction {
                case .backupSeedPhrase:
                    state.path.append(.recoveryPhraseDisplay(.init(flow: .onboarding)))
                    return .none
                case .initializeSDKAndLaunchWallet:
                    return initializeSDK()
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .splash:
                return .none
            }
        }
    }
    
    func recoveryPhraseDisplayDelegateReducer() -> Reduce<AppReducer.State, AppReducer.Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .recoveryPhraseDisplay(.delegate(delegateAction)))):
                switch delegateAction {
                case .initializeSDKAndLaunchWallet:
                    return initializeSDK()
                }
            case .destination, .initializeSDKFailed, .initializeSDKSuccess, .nukeWalletFailed, .nukeWalletSuccess, .path, .splash:
                return .none
            }
        }
    }
}
