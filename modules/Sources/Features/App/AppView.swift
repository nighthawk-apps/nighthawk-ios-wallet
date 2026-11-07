//
//  AppView.swift
//
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import DarkfiCore
import Generated
import Home
import ImportWallet
import ImportWalletSuccess
import Migrate
import RecoveryPhraseDisplay
import Splash
import SwiftUI
import TransactionDetail
import UIKit
import WalletCreated
import Welcome
import UIComponents
import Models

public struct AppView: View {
    @Bindable var store: StoreOf<AppReducer>
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject private var themes = NighthawkThemeController.shared

    public var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            SplashView(
                store: store.scope(
                    state: \.splash,
                    action: \.splash
                )
            )
            .toolbar(.hidden, for: .navigationBar)
        } destination: { pathStore in
            pathScreen(pathStore)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
                .background {
                    NighthawkPopGestureEnabler(enabled: store.path.count > 1) {
                        popVisible()
                    }
                }
        }
        .tint(themes.theme.primaryAccentColor)
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
        .onAppear {
            NighthawkMeshController.shared.restoreIfEnabled()
        }
        .onChange(of: scenePhase) {
            store.send(.scenePhaseChanged(scenePhase))
            NighthawkMeshController.shared.setForeground(scenePhase == .active)
        }
        .onChange(of: store.path.isEmpty) { _, isEmpty in
            // Splash stays mounted as the stack root. Mark it hidden once a
            // screen is pushed so scene-phase checks do not relaunch the wallet.
            store.send(isEmpty ? .splash(.onAppear) : .splash(.onDisappear))
        }
        .preferredColorScheme(themes.theme.colorScheme)
    }

    public init(store: StoreOf<AppReducer>) {
        self.store = store
    }
}

// MARK: - Path screens
private extension AppView {
    @ViewBuilder
    // swiftlint:disable:next cyclomatic_complexity
    func pathScreen(_ pathStore: StoreOf<AppReducer.Path>) -> some View {
        let showBackButton = store.path.count > 1

        Group {
            switch pathStore.case {
                case let .about(store):
                    AboutView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.About.title) {
                            self.popVisible()
                        }

                case let .advanced(store):
                    AdvancedView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.advancedTitle) {
                            self.popVisible()
                        }

                case let .backup(store):
                    RecoveryPhraseDisplayView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.popVisible()
                        }

                case let .changeServer(store):
                    ChangeServerView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.changeServerTitle) {
                            self.popVisible()
                        }

                case let .chatSettings(store):
                    ChatSettingsView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.chatSettingsTitle) {
                            self.popVisible()
                        }

                case let .daoHub(store):
                    let daoTitle: String? = switch store.screen {
                    case .hub: L10n.Nighthawk.DaoHub.title
                    case .daoDetail: store.selectedDao?.name ?? L10n.Nighthawk.DaoHub.title
                    case .proposalDetail: L10n.Nighthawk.DaoHub.proposal
                    }
                    DaoHubView(store: store)
                        .nighthawkChrome(
                            showBack: showBackButton || store.screen != .hub,
                            title: daoTitle
                        ) {
                            if store.screen != .hub {
                                store.send(.backTapped)
                            } else {
                                self.popVisible()
                            }
                        }

                case let .fiat(store):
                    FiatView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.fiatTitle) {
                            self.popVisible()
                        }

                case let .home(store):
                    HomeView(store: store)

                case let .importWallet(store):
                    ImportWalletView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.popVisible()
                        }

                case let .importWalletSuccess(store):
                    ImportWalletSuccessView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.popVisible()
                        }

                case let .migrate(store):
                    MigrateView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.popVisible()
                        }

                case let .notifications(store):
                    NotificationsView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.notificationsTitle) {
                            self.popVisible()
                        }

                case let .recoveryPhraseDisplay(store):
                    RecoveryPhraseDisplayView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.popVisible()
                        }

                case let .security(store):
                    SecurityView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.securityTitle) {
                            self.popVisible()
                        }

                case let .torNetwork(store):
                    TorNetworkView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.SettingsTab.networkPrivacyTitle) {
                            self.popVisible()
                        }

                case let .transactionDetail(store):
                    TransactionDetailView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.TransactionDetails.title) {
                            self.popVisible()
                        }

                case let .transactionHistory(store):
                    TransactionHistoryView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: L10n.Nighthawk.TransactionHistory.title) {
                            self.popVisible()
                        }

                case let .walletCreated(store):
                    WalletCreatedView(store: store)
                        .nighthawkChrome(showBack: showBackButton, title: nil) {
                            self.popVisible()
                        }

                case let .welcome(store):
                    WelcomeView(store: store)
                }
        }
        .toolbarColorScheme(themes.theme.colorScheme, for: .navigationBar)
    }

    func popVisible() {
        if let id = store.path.ids.last {
            store.send(.path(.popFrom(id: id)))
        }
    }
}

/// Hidden navigation-bar back buttons disable the interactive pop gesture.
/// Re-enable it for every pushed screen so swipe-back matches the stack.
private struct NighthawkPopGestureEnabler: UIViewControllerRepresentable {
    var enabled: Bool
    var onPop: () -> Void

    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller()
        controller.onPop = onPop
        return controller
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.enabled = enabled
        controller.onPop = onPop
        controller.sync()
    }

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        var enabled = true
        var onPop: () -> Void = {}
        private var observing = false

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            sync()
        }

        func sync() {
            guard let pop = navigationController?.interactivePopGestureRecognizer else { return }
            pop.isEnabled = enabled && (navigationController?.viewControllers.count ?? 0) > 1
            pop.delegate = self
            if !observing {
                pop.addTarget(self, action: #selector(interactivePopChanged(_:)))
                observing = true
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            enabled && (navigationController?.viewControllers.count ?? 0) > 1
        }

        @objc private func interactivePopChanged(_ gesture: UIGestureRecognizer) {
            guard gesture.state == .ended,
                  let nav = navigationController,
                  let coordinator = nav.transitionCoordinator,
                  !coordinator.isCancelled,
                  let from = coordinator.viewController(forKey: .from),
                  !nav.viewControllers.contains(from)
            else { return }
            onPop()
        }
    }
}

private extension View {
    @ViewBuilder
    func nighthawkChrome(showBack: Bool, title: String?, action: @escaping () -> Void) -> some View {
        if showBack {
            nighthawkTopBar(leading: .back, title: title, action: action)
        } else if let title {
            nighthawkTopBar(leading: .none, title: title)
        } else {
            safeAreaInset(edge: .top, spacing: 0) {
                if NighthawkThemeController.shared.theme.usesCyberpunkChrome {
                    Color.clear.frame(height: NighthawkLayout.wallpaperWordmarkClearance)
                }
            }
        }
    }
}
