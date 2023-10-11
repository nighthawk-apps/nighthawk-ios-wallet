//
//  Migrate.swift
//  
//
//  Created by Matthew Watt on 8/12/23.
//

import ComposableArchitecture
import Generated
import WalletStorage

public struct Migrate: Reducer {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        public var isLoading = false
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case continueTapped
        case delegate(Delegate)
        case restoreManuallyTapped
        
        public enum Alert: Equatable {
            case `continue`
        }
        
        public enum Delegate: Equatable {
            case initializeSDKAndLaunchWallet
            case importManually
        }
    }
    
    @Dependency(\.walletStorage) var walletStorage
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.dismiss):
                return .none
            case .alert(.presented(.continue)):
                return .send(.delegate(.importManually))
            case .continueTapped:
                state.isLoading = true
                do {
                    let phrase = try walletStorage.exportLegacyPhrase()
                    let birthday = try walletStorage.exportLegacyBirthday()
                    
                    // store the birthday and phrase found on the legacy keychain values
                    // into the wallet under the new keychain format.
                    try walletStorage.importWallet(phrase, birthday, .english)

                    // once we are sure that the values were stored under the new format,
                    // Delete legacy wallet storage and all the remaining values that don't
                    // be used anymore.
                    walletStorage.deleteLegacyWallet()
                    
                    return .send(.delegate(.initializeSDKAndLaunchWallet))
                } catch {
                    state.alert = AlertState.migrationFailed()
                }
                return .none
            case .delegate:
                return .none
            case .restoreManuallyTapped:
                state.isLoading = true
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    public init() {}
}

extension AlertState where Action == Migrate.Action.Alert {
    public static func migrationFailed() -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.MigrateScreen.MigrationFailed.title)
        } actions: {
            ButtonState(action: .continue) {
                TextState(L10n.Nighthawk.MigrateScreen.continue)
            }
        } message: {
            TextState(L10n.Nighthawk.MigrateScreen.MigrationFailed.description)
        }
    }
}
