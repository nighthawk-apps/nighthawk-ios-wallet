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
    let store: StoreOf<AppReducer>
    let tokenName: String
    let networkType: NetworkType
    
    @Environment(\.scenePhase) var scenePhase
    
    public var body: some View {
        NavigationStackStore(
            store.scope(
                state: \.path,
                action: { .path($0) }
            )
        ) {
            SplashView(
                store: store.scope(
                    state: \.splash,
                    action: { .splash($0) }
                )
            )
        } destination: { state in
            switch state {
            case .about:
                CaseLet(
                    /AppReducer.Path.State.about,
                     action: AppReducer.Path.Action.about,
                     then: { store in
                         AboutView(store: store)
                     }
                )
            case .advanced:
                CaseLet(
                    /AppReducer.Path.State.advanced,
                     action: AppReducer.Path.Action.advanced,
                     then: { store in
                         AdvancedView(store: store)
                     }
                )
            case .backup:
                CaseLet(
                    /AppReducer.Path.State.backup,
                     action: AppReducer.Path.Action.backup,
                     then: { store in
                         RecoveryPhraseDisplayView(store: store)
                     }
                )
            case .changeServer:
                CaseLet(
                    /AppReducer.Path.State.changeServer,
                     action: AppReducer.Path.Action.changeServer,
                     then: { store in
                         ChangeServerView(store: store)
                     }
                )
            case .externalServices:
                CaseLet(
                    /AppReducer.Path.State.externalServices,
                     action: AppReducer.Path.Action.externalServices,
                     then: { store in
                         ExternalServicesView(store: store)
                     }
                )
            case .fiat:
                CaseLet(
                    /AppReducer.Path.State.fiat,
                     action: AppReducer.Path.Action.fiat,
                     then: { store in
                         FiatView(store: store)
                     }
                )
            case .home:
                CaseLet(
                    /AppReducer.Path.State.home,
                     action: AppReducer.Path.Action.home,
                     then: { store in
                         HomeView(store: store, tokenName: tokenName)
                     }
                )
                .navigationTitle("")
                .toolbar(.hidden, for: .navigationBar)
            case .importWallet:
                CaseLet(
                    /AppReducer.Path.State.importWallet,
                     action: AppReducer.Path.Action.importWallet,
                     then: { store in
                         ImportWalletView(store: store)
                     }
                )
            case .importWalletSuccess:
                CaseLet(
                    /AppReducer.Path.State.importWalletSuccess,
                     action: AppReducer.Path.Action.importWalletSuccess,
                     then: { store in
                         ImportWalletSuccessView(store: store)
                     }
                )
                .toolbar(.hidden, for: .navigationBar)
            case .migrate:
                CaseLet(
                    /AppReducer.Path.State.migrate,
                     action: AppReducer.Path.Action.migrate,
                     then: { store in
                         MigrateView(store: store)
                     }
                )
            case .notifications:
                CaseLet(
                    /AppReducer.Path.State.notifications,
                     action: AppReducer.Path.Action.notifications,
                     then: { store in
                         NotificationsView(store: store)
                     }
                )
            case .recoveryPhraseDisplay:
                CaseLet(
                    /AppReducer.Path.State.recoveryPhraseDisplay,
                     action: AppReducer.Path.Action.recoveryPhraseDisplay,
                     then: { store in
                         RecoveryPhraseDisplayView(store: store)
                     }
                )
                .toolbar(.hidden, for: .navigationBar)
            case .security:
                CaseLet(
                    /AppReducer.Path.State.security,
                     action: AppReducer.Path.Action.security,
                     then: { store in
                         SecurityView(store: store)
                     }
                )
            case .transactionDetail:
                CaseLet(
                    /AppReducer.Path.State.transactionDetail,
                     action: AppReducer.Path.Action.transactionDetail,
                     then: { store in
                         TransactionDetailView(store: store, tokenName: tokenName)
                     }
                )
            case .transactionHistory:
                CaseLet(
                    /AppReducer.Path.State.transactionHistory,
                     action: AppReducer.Path.Action.transactionHistory,
                     then: { store in
                         TransactionHistoryView(store: store, tokenName: tokenName)
                     }
                )
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(L10n.Nighthawk.TransactionHistory.title)
                                .title()
                        }
                    }
                }
            case .walletCreated:
                CaseLet(
                    /AppReducer.Path.State.walletCreated,
                     action: AppReducer.Path.Action.walletCreated,
                     then: { store in
                         WalletCreatedView(store: store)
                     }
                )
                .toolbar(.hidden, for: .navigationBar)
            case .welcome:
                CaseLet(
                    /AppReducer.Path.State.welcome,
                     action: AppReducer.Path.Action.welcome,
                     then: { store in
                         WelcomeView(store: store)
                     }
                )
                .navigationTitle("")
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .tint(.white)
        .alert(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /AppReducer.Destination.State.alert,
            action: AppReducer.Destination.Action.alert
        )
        .onChange(of: scenePhase) { newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
    }
    
    public init(store: StoreOf<AppReducer>, tokenName: String, networkType: NetworkType) {
        self.store = store
        self.tokenName = tokenName
        self.networkType = networkType
    }
}
