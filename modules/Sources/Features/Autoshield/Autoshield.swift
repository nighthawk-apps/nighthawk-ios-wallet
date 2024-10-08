//
//  Autoshield.swift
//
//
//  Created by Matthew Watt on 9/18/23.
//

import ComposableArchitecture
import DerivationTool
import Foundation
import Generated
import MnemonicClient
import SDKSynchronizer
import UIKit
import UserPreferencesStorage
import WalletStorage
import ZcashLightClientKit
import ZcashSDKEnvironment

@Reducer
public struct Autoshield {
    
    @Reducer(state: .equatable, action: .equatable)
    public enum Path {
        case inProgress
        case success(AutoshieldSuccess)
        case failed(AutoshieldFailed)
    }
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var isShielding = false
        public var path = StackState<Path.State>()
        
        public init () {}
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case autoshieldInProgress
        case autoshieldSuccess
        case autoshieldFailed
        case path(StackAction<Path.State, Path.Action>)
        case positiveButtonTapped
        case warnBeforeLeavingApp(URL?)
        
        public enum Alert: Equatable {
            case openURL(URL?)
        }
    }
    
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case let .alert(.presented(.openURL(url))):
                if let url {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            case .autoshieldFailed:
                state.isShielding = false
                state.path.append(.failed(.init()))
                return .none
            case .autoshieldInProgress:
                state.path.append(.inProgress)
                return .none
            case .autoshieldSuccess:
                state.isShielding = false
                userStoredPreferences.setHasShownAutoshielding(false)
                state.path.append(.success(.init()))
                return .none
            case .path:
                return .none
            case .positiveButtonTapped:
                guard !state.isShielding else { return .none }
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                    let spendingKey = try derivationTool.deriveSpendingKey(seedBytes, 0, zcashSDKEnvironment.network.networkType)
                    
                    state.isShielding = true
                    return .run { send in
                        do {
                            await send(Autoshield.Action.autoshieldInProgress)
                            
                            guard let uAddress = try await sdkSynchronizer.getUnifiedAddress(0) else { throw "sdkSynchronizer.getUnifiedAddress" }
                            
                            let address = try uAddress.transparentReceiver()
                            let proposal = try await sdkSynchronizer.proposeShielding(0, .autoshieldingThreshold, .empty, address)
                            
                            guard let proposal else { throw "sdkSynchronizer.proposeShielding" }
                            
                            let result = try await sdkSynchronizer.createProposedTransactions(proposal, spendingKey)
                            
                            switch result {
                            case .failure:
                                await send(Autoshield.Action.autoshieldFailed)
                            case .success, .partial:
                                await send(Autoshield.Action.autoshieldSuccess)
                            }
                        } catch {
                            await send(Autoshield.Action.autoshieldFailed)
                        }
                    }
                } catch {
                    return .send(.autoshieldFailed)
                }
            case let .warnBeforeLeavingApp(url):
                state.alert = .warnBeforeLeavingApp(url)
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$alert, action: \.alert)
    }
    
    public init() {}
}

// MARK: - Alerts
extension AlertState where Action == Autoshield.Action.Alert {
    public static func warnBeforeLeavingApp(_ url: URL?) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.Autoshield.Alert.Redirecting.title)
        } actions: {
            ButtonState(action: .openURL(url)) {
                TextState(L10n.Nighthawk.Autoshield.Alert.Redirecting.openBrowser)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.Autoshield.Alert.Redirecting.details)
        }
    }
}
