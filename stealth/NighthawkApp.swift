import App
import BackgroundTasks
import ComposableArchitecture
import Foundation
import Generated
import Home
import SDKSynchronizer
import SwiftUI
import WalletStorage

@main
struct NighthawkApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var privacyBlur = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppView(
                    store: Store(
                        initialState: AppReducer.State()
                    ) {
                        AppReducer()
                    }
                )
                if privacyBlur {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    privacyBlur = false
                    // End DarkIRC background task; Chat reducer's scenePhaseChanged
                    // reconnects with a fresh event callback if the daemon died.
                    DarkircDaemonManager.shared.handleForegrounding()

                case .inactive:
                    privacyBlur = true

                case .background:
                    privacyBlur = true
                    // Don't stop darkirc — request a short background execution
                    // window so P2P/DAG can survive the OS grace period.
                    DarkircDaemonManager.shared.handleBackgrounding()

                    // Schedule background sync task
                    let request = BGAppRefreshTaskRequest(identifier: "com.nighthawkapps.sync")
                    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
                    do {
                        try BGTaskScheduler.shared.submit(request)
                    } catch {
                        print("Failed to schedule background task: \(error)")
                    }

                @unknown default:
                    break
                }
            }
        }
        .backgroundTask(.appRefresh("com.nighthawkapps.sync")) {
            _ = try? await SDKSynchronizerClient.liveValue.refreshNow()
        }
    }

    init() {
        FontFamily.registerAllCustomFonts()
    }
}
