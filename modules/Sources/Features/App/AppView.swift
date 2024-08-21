//
//  AppView.swift
//
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import Generated
import Home
import ImportWallet
import ImportWalletSuccess
import Migrate
import RecoveryPhraseDisplay
import Splash
import SwiftUI
import TransactionDetail
import WalletCreated
import Welcome
import ZcashLightClientKit

public struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>
    let tokenName: String
    let networkType: NetworkType
    @Environment(\.scenePhase) var scenePhase

    
    public var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \.path,
                action: \.path
            )
        ) {
            SplashView(
                store: store.scope(
                    state: \.splash,
                    action: \.splash
                )
            )
        } destination: { store in
            switch store.case {
            case let .about(store):
                AboutView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .advanced(store):
                AdvancedView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .backup(store):
                RecoveryPhraseDisplayView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .changeServer(store):
                ChangeServerView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .externalServices(store):
                ExternalServicesView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .fiat(store):
                FiatView(store: store, tokenName: tokenName)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .home(store):
                HomeView(store: store, tokenName: tokenName)
                    .navigationTitle("")
                    .toolbar(.hidden, for: .navigationBar)
                
            case let .importWallet(store):
                ImportWalletView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .importWalletSuccess(store):
                ImportWalletSuccessView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
                
            case let .migrate(store):
                MigrateView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .notifications(store):
                NotificationsView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .recoveryPhraseDisplay(store):
                RecoveryPhraseDisplayView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
                
            case let .security(store):
                SecurityView(store: store)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .transactionDetail(store):
                TransactionDetailView(store: store, tokenName: tokenName)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .transactionHistory(store):
                TransactionHistoryView(store: store, tokenName: tokenName)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            VStack {
                                Text(L10n.Nighthawk.TransactionHistory.title)
                                    .title()
                            }
                        }
                    }
                    .toolbarColorScheme(.dark, for: .navigationBar)
                
            case let .walletCreated(store):
                WalletCreatedView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
                
            case let .welcome(store):
                WelcomeView(store: store)
                    .navigationTitle("")
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .tint(.white)
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
        .onChange(of: scenePhase) { newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
        .preferredColorScheme(store.nighthawkColorScheme)
    }
    
    public init(store: StoreOf<AppReducer>, tokenName: String, networkType: NetworkType) {
        self.store = store
        self.tokenName = tokenName
        self.networkType = networkType
    }
}
