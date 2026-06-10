import App
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
    
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    initialState: AppReducer.State()
                ) {
                    AppReducer()
                }
            )
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    // Chat tab owns darkirc lifecycle (connect on appear, disconnect on
                    // background). Starting here races with Chat and can leave the daemon
                    // running without a message callback.
                    break
                    
                case .background:
                    // Don't stop darkirc — let iOS's background grace period
                    // keep it alive for continued DAG sync.
                    DarkircDaemonManager.shared.handleBackgrounding()
                    
                default:
                    break
                }
            }
        }
    }
    
    init() {
        FontFamily.registerAllCustomFonts()
    }
}
