//
//  AppView.swift
//  
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import Home
import RecoveryPhraseDisplay
import Splash
import SwiftUI
import WalletCreated
import Welcome
import ZcashLightClientKit

public struct AppView: View {
    let store: StoreOf<AppReducer>
    let tokenName: String
    let networkType: NetworkType
    
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
            case .home:
                CaseLet(
                    /AppReducer.Path.State.home,
                     action: AppReducer.Path.Action.home,
                     then: { store in
                         HomeView(store: store, tokenName: tokenName)
                             .toolbar(.hidden, for: .navigationBar)
                     }
                )
            case .recoveryPhraseDisplay:
                CaseLet(
                    /AppReducer.Path.State.recoveryPhraseDisplay,
                     action: AppReducer.Path.Action.recoveryPhraseDisplay,
                     then: { store in
                         RecoveryPhraseDisplayView(store: store)
                             .toolbar(.hidden, for: .navigationBar)
                     }
                )
            case .walletCreated:
                CaseLet(
                    /AppReducer.Path.State.walletCreated,
                     action: AppReducer.Path.Action.walletCreated,
                     then: { store in
                         WalletCreatedView(store: store)
                             .toolbar(.hidden, for: .navigationBar)
                     }
                )
            case .welcome:
                CaseLet(
                    /AppReducer.Path.State.welcome,
                     action: AppReducer.Path.Action.welcome,
                     then: { store in
                         WelcomeView(store: store)
                             .toolbar(.hidden, for: .navigationBar)
                     }
                )
            }
        }
        .alert(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /AppReducer.Destination.State.alert,
            action: AppReducer.Destination.Action.alert
        )
    }
    
    public init(store: StoreOf<AppReducer>, tokenName: String, networkType: NetworkType) {
        self.store = store
        self.tokenName = tokenName
        self.networkType = networkType
    }
}
