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
    @Bindable var store: StoreOf<Splash>
    
    @Environment(\.scenePhase) var scenePhase
    
    public var body: some View {
        VStack {
            Spacer()
            
            VStack {
                NighthawkLogo()
                    .padding(.bottom, 10)
                
                Text(L10n.Nighthawk.Splash.subtitle)
                    .paragraph()
            }
            
            if store.hasAttemptedAuthentication && !store.authenticated {
                Button(
                    L10n.Nighthawk.Splash.retry,
                    action: { store.send(.retryTapped) }
                )
                .buttonStyle(.nighthawkPrimary())
                .padding(.top, 8)
            }

            Spacer()
        }
        .onChange(of: scenePhase) {
            store.send(.scenePhaseChanged(scenePhase))
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
    
    public init(store: StoreOf<Splash>) {
        self.store = store
    }
}

