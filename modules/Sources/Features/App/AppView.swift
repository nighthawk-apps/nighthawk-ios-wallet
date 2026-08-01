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
import UIComponents

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
    // swiftlint:disable:next cyclomatic_complexity
    func pathScreen(id: StackElementID) -> some View {
        let showBackButton = store.path.count > 1

        if let pathStore = store.scope(state: \.path[id: id], action: \.path[id: id]) {
            Group {
                switch pathStore.case {
                case let .about(store):
                    AboutView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.About.title) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .advanced(store):
                    AdvancedView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.advancedTitle) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .backup(store):
                    RecoveryPhraseDisplayView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .changeServer(store):
                    ChangeServerView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.changeServerTitle) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .chatSettings(store):
                    ChatSettingsView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: "Chat settings") {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .daoHub(store):
                    // DaoHub owns internal back on detail/proposal; App back only on hub.
                    DaoHubView(store: store)
                        .nighthawkChrome(
                            showBack: showBackButton && store.screen == .hub,
                            title: store.screen == .hub ? "DAO Hub" : nil
                        ) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .fiat(store):
                    FiatView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.fiatTitle) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .home(store):
                    HomeView(store: store)

                case let .importWallet(store):
                    ImportWalletView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .importWalletSuccess(store):
                    ImportWalletSuccessView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .migrate(store):
                    MigrateView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .notifications(store):
                    NotificationsView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.notificationsTitle) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .recoveryPhraseDisplay(store):
                    RecoveryPhraseDisplayView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .security(store):
                    SecurityView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.securityTitle) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .torNetwork(store):
                    TorNetworkView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: "Tor network") {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .transactionDetail(store):
                    TransactionDetailView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.TransactionDetails.title) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .transactionHistory(store):
                    TransactionHistoryView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.TransactionHistory.title) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .walletCreated(store):
                    WalletCreatedView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.store.send(.path(.popFrom(id: id)))
                        }

                case let .welcome(store):
                    WelcomeView(store: store)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private extension View {
    @ViewBuilder
    func nighthawkChrome(showBack: Bool, title: String?, action: @escaping () -> Void) -> some View {
        if showBack {
            nighthawkTopBar(leading: .back, title: title, action: action)
        } else {
            self
        }
    }
}
