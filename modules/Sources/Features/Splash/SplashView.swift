//
//  SplashView.swift
//
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct SplashView: View {
    @Bindable var store: StoreOf<Splash>

    @Environment(\.scenePhase) var scenePhase

    public var body: some View {
        VStack {
            Spacer()

            if store.requiresPinEntry {
                pinUnlockCard
                    .padding(.horizontal, 24)
            } else if store.hasAttemptedAuthentication && !store.authenticated {
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

    private var pinUnlockCard: some View {
        VStack(spacing: 14) {
            Text("Enter App PIN")
                .subtitleMedium(color: Asset.Colors.Nighthawk.textHeader.color)

            HStack(spacing: 12) {
                ForEach(0..<SecurityPinStore.pinLength, id: \.self) { idx in
                    Circle()
                        .fill(
                            idx < store.pinInput.count
                                ? Asset.Colors.Nighthawk.peach.color
                                : Asset.Colors.Nighthawk.steelBorder.color
                        )
                        .frame(width: 14, height: 14)
                }
            }

            SecureField(
                "6-digit PIN",
                text: Binding(
                    get: { store.pinInput },
                    set: { store.send(.pinInputChanged($0)) }
                )
            )
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Asset.Colors.Nighthawk.navy.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Asset.Colors.Nighthawk.steelBorder.color, lineWidth: 1)
            )
            .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

            if let error = store.pinError {
                Text(error)
                    .caption(color: StealthTheme.Colors.statusDanger)
            }

            Button("Unlock") {
                store.send(.submitPinTapped)
            }
            .buttonStyle(.nighthawkPrimary())
            .disabled(store.pinInput.count != SecurityPinStore.pinLength)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.Colors.Nighthawk.navy.color.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Asset.Colors.Nighthawk.steelBorder.color, lineWidth: 1)
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
            let stuck = elapsed >= 12 || failed
            VStack(spacing: 12) {
                ProgressView(value: NymSplashEstimate.fraction(elapsed: elapsed, ready: false))
                    .tint(Asset.Colors.Nighthawk.peach.color)
                Text(failed ? "Nym mixnet connection failed" : "Connecting to the Nym mixnet… \(Int(elapsed)) s")
                    .paragraph(color: failed ? StealthTheme.Colors.statusDanger : Asset.Colors.Nighthawk.textHeader.color)
                    .multilineTextAlignment(.center)
                if stuck {
                    Text("Taking longer than usual. Keep waiting, or continue without Nym.")
                        .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                        .multilineTextAlignment(.center)
                    if failed {
                        Button("Retry", action: onRetry)
                            .buttonStyle(.nighthawkPrimary())
                    }
                }
                Button("Continue without Nym", action: onContinue)
                    .buttonStyle(.nighthawkSecondary())
                Text("Wallet and chat use your regular network for this session. You can switch back to Nym in Settings.")
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    .multilineTextAlignment(.center)
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
