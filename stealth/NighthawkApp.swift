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
                    // Avoid starting P2P/darkirc during onboarding — it can contend with
                    // wallet FFI on the main thread and make the welcome screen feel stuck.
                    if (try? WalletStorageClient.live().areKeysPresent()) == true {
                        DarkircDaemonManager.shared.ensureRunning()
                    }
                    
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
