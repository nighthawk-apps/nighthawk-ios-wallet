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
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()

                VStack {
                    NighthawkLogo(size: .tabHeader)
                        .padding(.bottom, 10)

                    Text(L10n.Nighthawk.Splash.subtitle)
                        .paragraph()

                    if let status = store.statusMessage {
                        Text(status)
                            .paragraph()
                            .padding(.top, 12)
                            .accessibilityLabel(status)
                    }
                }

                if store.hasAttemptedAuthentication && !store.authenticated {
                    Button(
                        L10n.Nighthawk.Splash.retry,
                        action: { store.send(.retryTapped) }
                    )
                    .buttonStyle(.nighthawkPrimary())
                    .padding(.top, 8)
                } else if store.statusMessage?.contains("Tor bootstrap failed") == true {
                    Button(
                        L10n.Nighthawk.Splash.retry,
                        action: { store.send(.bootstrapTorThenLaunch) }
                    )
                    .buttonStyle(.nighthawkPrimary())
                    .padding(.top, 8)
                }

                Spacer()
            }

            // Bottom-center escape hatch (Android splash parity).
            if store.showDisableTorButton {
                VStack(spacing: 8) {
                    Button("Continue without Tor") {
                        store.send(.disableTorAndContinue)
                    }
                    .buttonStyle(.nighthawkSecondary())

                    Text("Uses your regular network. You can re-enable Tor in Settings.")
                        .paragraph()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 48)
            }
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
