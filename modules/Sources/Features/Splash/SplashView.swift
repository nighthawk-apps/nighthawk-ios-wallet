//
//  SplashView.swift
//  
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct SplashView: View {
    let store: StoreOf<Splash>
    
    @Environment(\.scenePhase) var scenePhase
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Spacer()
                
                VStack {
                    NighthawkLogo()
                        .padding(.bottom, 10)
                    
                    Text(L10n.Nighthawk.Splash.subtitle)
                        .paragraph()
                }
                
                if viewStore.hasAttemptedAuthentication && !viewStore.authenticated {
                    Button(
                        L10n.Nighthawk.Splash.retry,
                        action: { viewStore.send(.retryTapped) }
                    )
                    .buttonStyle(.nighthawkPrimary())
                    .padding(.top, 8)
                }

                Spacer()
                
                Asset.Assets.Icons.Nighthawk.poweredByZcash
                    .image
                    .resizable()
                    .frame(width: 131, height: 20)
                    .padding(.bottom, 44)
            }
            .onChange(of: scenePhase) { newPhase in viewStore.send(.scenePhaseChanged(newPhase)) }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onDisappear {
                viewStore.send(.onDisappear)
            }
        }
        .applyNighthawkBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
    
    public init(store: StoreOf<Splash>) {
        self.store = store
    }
}

