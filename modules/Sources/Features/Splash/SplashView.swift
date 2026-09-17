//
//  SplashView.swift
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
                } else if store.statusMessage == L10n.Nighthawk.Splash.torFailed {
                    Button(
                        L10n.Nighthawk.Splash.retry,
                        action: { store.send(.bootstrapTorThenLaunch) }
                    )
                    .buttonStyle(.nighthawkPrimary())
                    .padding(.top, 8)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                if store.showDisableTorButton {
                    Button(L10n.Nighthawk.Splash.continueWithoutTor) {
                        store.send(.disableTorAndContinue)
                    }
                    .buttonStyle(.nighthawkSecondary())

                    Text(L10n.Nighthawk.Splash.continueWithoutTorHint)
                        .paragraph()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if !store.appVersion.isEmpty {
                    Text(L10n.Nighthawk.Splash.version(store.appVersion))
                        .caption(color: Color.white.opacity(0.7))
                        .accessibilityLabel(L10n.Nighthawk.Splash.version(store.appVersion))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
        }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
        .task {
            // `.task` fires when the view joins the hierarchy (more reliable than
            // `onAppear` behind a UIKit launch storyboard).
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
