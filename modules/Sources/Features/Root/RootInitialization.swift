//
//  RootInitialization.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 01.12.2022.
//

import ComposableArchitecture
import Foundation
import Generated
import ZcashLightClientKit
import Models
import NHHome
import SwiftUI
import Utils

/// In this file is a collection of helpers that control all state and action related operations
/// for the `RootReducer` with a connection to the app/wallet initialization and erasure of the wallet.
extension RootReducer {
    public enum InitializationAction: Equatable {
        case authenticate
        case authenticationResponse(Bool)
        case checkBackupPhraseValidation
        case checkWalletInitialization
        case createNewWallet
        case initializeSDK
        case initialSetups
        case initializationFailed(ZcashError)
        case migrateLegacyWallet
        case finishManualRestore
        case nukeWallet
        case nukeWalletRequest
        case respondToWalletInitializationState(InitializationState)
        case scene(SceneAction)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func initializationReduce() -> Reduce<RootReducer.State, RootReducer.Action> {
        Reduce { state, action in
            switch action {
            case .initialization(.authenticate):
//                if !state.welcomeState.hasAuthenticated {
//                    return .task {
//                        let context = localAuthenticationContext()
//                        
//                        do {
//                            if try context.canEvaluatePolicy(.deviceOwnerAuthentication) {
//                                return try await .initialization(
//                                    .authenticationResponse(
//                                        context.evaluatePolicy(
//                                            .deviceOwnerAuthentication,
//                                            L10n.Nighthawk.LocalAuthentication.accessWalletReason
//                                        )
//                                    )
//                                )
//                            } else {
//                                return .initialization(.authenticationResponse(false))
//                            }
//                        } catch {
//                            return .initialization(.authenticationResponse(false))
//                        }
//                    }
//                }
                return .none
//            case .welcome(.retryTapped):
//                return .task {
//                    let context = localAuthenticationContext()
//
//                    do {
//                        if try context.canEvaluatePolicy(.deviceOwnerAuthentication) {
//                            return try await .initialization(
//                                .authenticationResponse(
//                                    context.evaluatePolicy(
//                                        .deviceOwnerAuthentication,
//                                        L10n.Nighthawk.LocalAuthentication.accessWalletReason
//                                    )
//                                )
//                            )
//                        } else {
//                            return .initialization(.authenticationResponse(false))
//                        }
//                    } catch {
//                        return .initialization(.authenticationResponse(false))
//                    }
//                }
            case let .initialization(.authenticationResponse(authenticated)):
//                state.welcomeState.hasAuthenticated = authenticated
                if authenticated {
                    return .run { send in
                        await send(.initialization(.initializeSDK))
                        await send(.initialization(.checkBackupPhraseValidation))
                    }
                }
                return .none
                
            case let .initialization(.scene(.didChangePhase(newPhase))):
                if state.shouldResetToSplash(for: newPhase) && userStoredPreferences.areBiometricsEnabled() {
//                    state.welcomeState.hasAuthenticated = false
                    return .concatenate(
                        .cancel(id: SynchronizerCancelId.timer),
                        .send(.destination(.updateDestination(.welcome)))
                    )
                } else if newPhase == .active {
                    return EffectTask(value: .initialization(.initialSetups))
                        .delay(for: 0.02, scheduler: mainQueue)
                        .eraseToEffect()
                }
                return .none
                
            case .initialization(.initialSetups):
                // TODO: [#524] finish all the wallet events according to definition, https://github.com/zcash/secant-ios-wallet/issues/524
                LoggerProxy.event(".appDelegate(.didFinishLaunching)")
                /// We need to fetch data from keychain, in order to be 100% sure the keychain can be read we delay the check a bit
                return EffectTask(value: .initialization(.checkWalletInitialization))
                    .delay(for: 0.02, scheduler: mainQueue)
                    .eraseToEffect()

                /// Evaluate the wallet's state based on keychain keys and database files presence
            case .initialization(.checkWalletInitialization):
                let walletState = RootReducer.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    zcashNetwork: zcashNetwork
                )
                return EffectTask(value: .initialization(.respondToWalletInitializationState(walletState)))

                /// Respond to all possible states of the wallet and initiate appropriate side effects including errors handling
            case .initialization(.respondToWalletInitializationState(let walletState)):
                switch walletState {
                case .failed:
                    state.appInitializationState = .failed
                    state.alert = AlertState.walletStateFailed(walletState)
                    return .none
                case .needsMigration:
                    state.appInitializationState = .needsMigration
                    state.destinationState.destination = .migrate
                    return .none
                case .keysMissing:
                    state.appInitializationState = .keysMissing
                    state.alert = AlertState.walletStateFailed(walletState)
                    return .none
                case .initialized, .filesMissing:
                    if walletState == .filesMissing {
                        state.appInitializationState = .filesMissing
                    }
                    
                    if userStoredPreferences.areBiometricsEnabled() {
                        return .run { send in await send(.initialization(.authenticate)) }
                    } else {
                        return .run { send in
                            await send(.initialization(.initializeSDK))
                            await send(.initialization(.checkBackupPhraseValidation))
                        }
                    }
                case .uninitialized:
                    state.appInitializationState = .uninitialized
                    return .none
//                    return EffectTask(value: .destination(.updateDestination(.onboarding)))
//                        .delay(for: 3, scheduler: mainQueue)
//                        .eraseToEffect()
//                        .cancellable(id: CancelId.timer, cancelInFlight: true)
                }

                /// Stored wallet is present, database files may or may not be present, trying to initialize app state variables and environments.
                /// When initialization succeeds user is taken to the home screen.
            case .initialization(.initializeSDK):
                do {
                    state.storedWallet = try walletStorage.exportWallet()

                    guard let storedWallet = state.storedWallet else {
                        state.appInitializationState = .failed
                        state.alert = AlertState.cantLoadSeedPhrase()
                        return .none
                    }

                    let birthday = state.storedWallet?.birthday?.value() ?? zcashSDKEnvironment.latestCheckpoint(zcashNetwork)

                    try mnemonic.isValid(storedWallet.seedPhrase.value())
                    let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                    let spendingKey = try derivationTool.deriveSpendingKey(seedBytes, 0, zcashNetwork.networkType)
                    let viewingKey = try derivationTool.deriveUnifiedFullViewingKey(spendingKey, zcashNetwork.networkType)
                    
                    return .run { send in
                        do {
                            try await sdkSynchronizer.prepareWith(seedBytes, viewingKey, birthday)
                            try await sdkSynchronizer.start(false)
                        } catch {
                            await send(.initialization(.initializationFailed(error.toZcashError())))
                        }
                    }
                } catch {
                    return EffectTask(value: .initialization(.initializationFailed(error.toZcashError())))
                }

            case .initialization(.checkBackupPhraseValidation):
                guard let storedWallet = state.storedWallet else {
                    state.appInitializationState = .failed
                    state.alert = AlertState.cantLoadSeedPhrase()
                    return .none
                }

                var landingDestination = RootReducer.DestinationState.Destination.nhHome
                state.appInitializationState = .initialized

                return EffectTask(value: .destination(.updateDestination(landingDestination)))
                    .delay(for: 3, scheduler: mainQueue)
                    .eraseToEffect()
                    .cancellable(id: CancelId.timer, cancelInFlight: true)

            case .initialization(.createNewWallet):
                do {
                    // get the random english mnemonic
                    let newRandomPhrase = try mnemonic.randomMnemonic()
                    let birthday = zcashSDKEnvironment.latestCheckpoint(zcashNetwork)

                    // store the wallet to the keychain
                    try walletStorage.importWallet(newRandomPhrase, birthday, .english)

                    // start the backup phrase validation test
                    let randomRecoveryPhraseWords = mnemonic.asWords(newRandomPhrase)
                    let recoveryPhrase = RecoveryPhrase(words: randomRecoveryPhraseWords.map { $0.redacted })
                    state.phraseDisplayState.phrase = recoveryPhrase

                    return EffectTask(value: .initialization(.initializeSDK))
                } catch {
                    state.alert = AlertState.cantCreateNewWallet(error.toZcashError())
                }
                return .none
                
            case .initialization(.migrateLegacyWallet):
                do {
                    let phrase = try walletStorage.exportLegacyPhrase()
                    let birthday = try walletStorage.exportLegacyBirthday()
                    

                    // store the birthday and phrase found on the legacy keychain values
                    // into the wallet under the new keychain format.
                    try walletStorage.importWallet(phrase, birthday, .english)

                    // once we are sure that the values were stored under the new format,
                    // Delete legacy wallet storage and all the remaining values that don't
                    // be used anymore.
                    walletStorage.nukeLegacyWallet()
                    
                    return .concatenate(
                        EffectTask(value: .initialization(.initializeSDK)),
                        EffectTask(value: .initialization(.checkBackupPhraseValidation))
                    )
                } catch {
                    state.alert = AlertState.migrationFailed()
                }
                return .none

            case .initialization(.nukeWalletRequest):
                state.alert = AlertState.wipeRequest()
                return .none
            
            case .initialization(.nukeWallet),
                 .nhHome(.settings(.path(.element(id: _, action: .advanced(.nukeWalletConfirmed))))):
                guard let wipePublisher = sdkSynchronizer.wipe() else {
                    return EffectTask(value: .nukeWalletFailed)
                }
                return wipePublisher
                    .replaceEmpty(with: Void())
                    .map { _ in return RootReducer.Action.nukeWalletSucceeded }
                    .replaceError(with: RootReducer.Action.nukeWalletFailed)
                    .receive(on: mainQueue)
                    .eraseToEffect()
                    .cancellable(id: SynchronizerCancelId.timer, cancelInFlight: true)

            case .nukeWalletSucceeded:
                walletStorage.nukeWallet()
                state.nhHomeState.settingsState.path = .init()
                state.nhHomeState.destination = .wallet
                state.onboardingState.destination = nil
                return .concatenate(
                    .cancel(id: SynchronizerCancelId.timer),
                    EffectTask(value: .initialization(.checkWalletInitialization))
                )

            case .nukeWalletFailed:
                let backDestination: EffectTask<RootReducer.Action>
                if let previousDestination = state.destinationState.previousDestination {
                    backDestination = EffectTask(value: .destination(.updateDestination(previousDestination)))
                } else {
                    backDestination = EffectTask(value: .destination(.updateDestination(state.destinationState.destination)))
                }
                state.alert = AlertState.wipeFailed()
                return .concatenate(
                    .cancel(id: SynchronizerCancelId.timer),
                    backDestination
                )
                
            case .migrate(.continueTapped):
                return .task { .initialization(.migrateLegacyWallet) }
                
            case .migrate(.restoreManuallyTapped):
                guard let wipePublisher = sdkSynchronizer.wipe() else {
                    return EffectTask(value: .nukeWalletFailed)
                }
                return wipePublisher
                    .replaceEmpty(with: Void())
                    .map { _ in return RootReducer.Action.initialization(.finishManualRestore) }
                    .replaceError(with: RootReducer.Action.nukeWalletFailed)
                    .receive(on: mainQueue)
                    .eraseToEffect()
                    .cancellable(id: SynchronizerCancelId.timer, cancelInFlight: true)
                
            case .initialization(.finishManualRestore):
                walletStorage.nukeWallet()
                walletStorage.nukeLegacyWallet()
                return .task { .initialization(.respondToWalletInitializationState(.uninitialized)) }

            case .onboarding(.importWallet(.successfullyRecovered)), .onboarding(.nhImportWallet(.importWalletSuccess(.viewWallet))):
                return EffectTask(value: .destination(.updateDestination(.nhHome)))

            case .onboarding(.importWallet(.initializeSDK)), .onboarding(.nhImportWallet(.initializeSDK)):
                return EffectTask(value: .initialization(.initializeSDK))

            case .onboarding(.createNewWallet):
                return EffectTask(value: .initialization(.createNewWallet))

            case .initialization(.initializationFailed(let error)):
                state.appInitializationState = .failed
                state.alert = AlertState.initializationFailed(error)
                return .none
                
            case .nhHome, .destination, .migrate, .onboarding, .phraseDisplay,
                /*.welcome,*/ .binding, .alert:
                return .none
            }
        }
    }
}

// MARK: - Implementation
private extension RootReducer.State {
    func shouldResetToSplash(for phase: ScenePhase) -> Bool {
        phase == .inactive
        && !nhHomeState.settingsState.path.contains(where: { (/NHSettingsReducer.Path.State.security).extract(from: $0) != nil })
        && nhHomeState.destination != .transfer
    }
}
