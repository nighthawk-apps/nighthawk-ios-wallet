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
                NighthawkLogo(size: .tabHeader)
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

            if store.waitingForNym {
                NymSplashProgressView(
                    startedAt: store.nymStartedAt ?? Date(),
                    failed: store.nymFailed,
                    onRetry: { store.send(.retryNym) },
                    onContinue: { store.send(.continueWithoutNym) }
                )
                .padding(.top, 16)
                .padding(.horizontal, 24)
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

private struct NymSplashProgressView: View {
    let startedAt: Date
    let failed: Bool
    let onRetry: () -> Void
    let onContinue: () -> Void

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 0.5)) { context in
            let elapsed = context.date.timeIntervalSince(startedAt)
            let stuck = elapsed >= 20 || failed
            VStack(spacing: 8) {
                ProgressView(value: NymSplashEstimate.fraction(elapsed: elapsed, ready: false))
                    .tint(Asset.Colors.Nighthawk.peach.color)
                Text(failed ? "Nym mixnet connection failed" : "Connecting to the Nym mixnet… \(Int(elapsed)) s")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                if stuck {
                    Text("Taking longer than usual. Keep waiting, or continue without Nym.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                    if failed {
                        Button("Retry", action: onRetry)
                    }
                    Button("Continue without Nym", action: onContinue)
                    Text("Wallet and chat use your regular network. You can switch back to Nym in Settings.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

private enum NymSplashEstimate {
    static func fraction(elapsed: TimeInterval, ready: Bool) -> Double {
        if ready { return 1 }
        return 0.95 * (1 - exp(-max(elapsed, 0) / 8))
    }
}
