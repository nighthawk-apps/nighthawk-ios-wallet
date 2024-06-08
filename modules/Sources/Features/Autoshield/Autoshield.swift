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

public struct Autoshield: Reducer {
    let networkType: NetworkType
    
    public struct Path: Reducer {
        public enum State: Equatable {
            case inProgress
            case success(AutoshieldSuccess.State = .init())
            case failed(AutoshieldFailed.State = .init())
        }
        
        public enum Action: Equatable {
            case inProgress(Never)
            case success(AutoshieldSuccess.Action)
            case failed(AutoshieldFailed.Action)
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.success, action: /Action.success) {
                AutoshieldSuccess()
            }
            
            Scope(state: /State.failed, action: /Action.failed) {
                AutoshieldFailed()
            }
        }
    }
    
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
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
                state.path.append(.failed())
                return .none
            case .autoshieldInProgress:
                state.path.append(.inProgress)
                return .none
            case .autoshieldSuccess:
                state.isShielding = false
                userStoredPreferences.setHasShownAutoshielding(false)
                state.path.append(.success())
                return .none
            case .path:
                return .none
            case .positiveButtonTapped:
                guard !state.isShielding else { return .none }
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                    let spendingKey = try derivationTool.deriveSpendingKey(seedBytes, 0, networkType)
                    
                    state.isShielding = true
                    return .run { [amount = sdkSynchronizer.latestState().accountBalance?.unshielded ?? .zero] send in
                        do {
                            await send(Autoshield.Action.autoshieldInProgress)
                            _ = try await sdkSynchronizer.shieldFunds(
                                spendingKey,
                                .init(string: L10n.Nighthawk.Autoshield.shieldingMemo),
                                amount
                            )
                            await send(Autoshield.Action.autoshieldSuccess)
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
        .forEach(\.path, action: /Action.path) {
            Path()
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
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
