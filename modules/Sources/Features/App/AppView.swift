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

public struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>
    @Environment(\.scenePhase) var scenePhase
    
    public var body: some View {
        Group {
            if store.path.isEmpty {
                SplashView(
                    store: store.scope(
                        state: \.splash,
                        action: \.splash
                    )
                )
            } else if let topID = store.path.ids.last {
                pathScreen(id: topID)
            }
        }
        .tint(.white)
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
        .onChange(of: scenePhase) {
            store.send(.scenePhaseChanged(scenePhase))
        }
        .preferredColorScheme(store.nighthawkColorScheme)
    }
    
    public init(store: StoreOf<AppReducer>) {
        self.store = store
    }
}

// MARK: - Path screens
private extension AppView {
    @ViewBuilder
    func pathScreen(id: StackElementID) -> some View {
        let showBackButton = store.path.count > 1
        
        if let pathStore = store.scope(state: \.path[id: id], action: \.path[id: id]) {
            Group {
                switch pathStore.case {
            case let .about(store):
                AboutView(store: store)
                
            case let .advanced(store):
                AdvancedView(store: store)
                
            case let .backup(store):
                RecoveryPhraseDisplayView(store: store)
                
            case let .changeServer(store):
                ChangeServerView(store: store)
                
            case let .externalServices(store):
                ExternalServicesView(store: store)
                
            case let .fiat(store):
                FiatView(store: store)
                
            case let .home(store):
                HomeView(store: store)
                
            case let .importWallet(store):
                ImportWalletView(store: store)
                
            case let .importWalletSuccess(store):
                ImportWalletSuccessView(store: store)
                
            case let .migrate(store):
                MigrateView(store: store)
                
            case let .notifications(store):
                NotificationsView(store: store)
                
            case let .recoveryPhraseDisplay(store):
                RecoveryPhraseDisplayView(store: store)
                
            case let .security(store):
                SecurityView(store: store)
                
            case let .transactionDetail(store):
                TransactionDetailView(store: store)
                
            case let .transactionHistory(store):
                TransactionHistoryView(store: store)
                
            case let .walletCreated(store):
                WalletCreatedView(store: store)
                
            case let .welcome(store):
                WelcomeView(store: store)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .modify {
            if showBackButton {
                $0.showNighthawkBackButton {
                    store.send(.path(.popFrom(id: id)))
                }
            } else {
                $0
            }
        }
        }
    }
}
