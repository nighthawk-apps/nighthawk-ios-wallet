import SwiftUI
import StoreKit
import ComposableArchitecture
import Generated
import Models
import RecoveryPhraseDisplay
import Welcome
import Migrate
import OnboardingFlow
import NHHome
import ZcashLightClientKit

public struct RootView: View {
    let store: RootStore
    let tokenName: String
    let networkType: NetworkType
    @Environment(\.scenePhase) var scenePhase

    public init(store: RootStore, tokenName: String, networkType: NetworkType) {
        self.store = store
        self.tokenName = tokenName
        self.networkType = networkType
    }
    
    public var body: some View {
        switchOverDestination()
    }
}

private extension RootView {
    @ViewBuilder func switchOverDestination() -> some View {
        WithViewStore(store) { viewStore in
            Group {
                switch viewStore.destinationState.destination {
                case .nhHome:
                    NavigationView {
                        NHHomeView(
                            store: store.scope(
                                state: \.nhHomeState,
                                action: RootReducer.Action.nhHome
                            ),
                            tokenName: tokenName
                        )
                    }
                    .navigationViewStyle(.stack)
                    .tint(.white)
                    .onChange(of: scenePhase) { newPhase in
                        viewStore.send(.initialization(.scene(.didChangePhase(newPhase))))
                    }
                    
                case .phraseDisplay:
                    NavigationView {
                        RecoveryPhraseDisplayView(
                            store: store.scope(
                                state: \.phraseDisplayState,
                                action: RootReducer.Action.phraseDisplay
                            )
                        )
                    }
                    
                case .welcome:
                    EmptyView()
//                    NHWelcomeView(
//                        store: store.scope(
//                            state: \.welcomeState,
//                            action: RootReducer.Action.welcome
//                        )
//                    )
//                    .onChange(of: scenePhase) { newScene in
//                        viewStore.send(.initialization(.scene(.didChangePhase(newScene))))
//                    }
                case .migrate:
                    MigrateView(
                        store: store.scope(
                            state: \.migrateState,
                            action: RootReducer.Action.migrate
                        )
                    )
                }
            }
            .onOpenURL(perform: { viewStore.goToDeeplink($0) })
            .alert(store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            ))
        }
    }
}

// MARK: - Previews

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RootView(
                store: RootStore(
                    initialState: .placeholder,
                    reducer: RootReducer(tokenName: "ZEC", zcashNetwork: ZcashNetworkBuilder.network(for: .testnet))
                ),
                tokenName: "ZEC",
                networkType: .testnet
            )
        }
    }
}
