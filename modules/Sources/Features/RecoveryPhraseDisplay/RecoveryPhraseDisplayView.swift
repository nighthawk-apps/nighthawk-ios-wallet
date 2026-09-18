//
//  NHRecoveryPhraseDisplayView.swift
//  stealth
//

import ComposableArchitecture
import ExportSeed
import Generated
import Models
import PDFKit
import SwiftUI
import UIComponents

public struct RecoveryPhraseDisplayView: View {
    @Bindable var store: StoreOf<RecoveryPhraseDisplay>
    @State private var isCaptured = false

    public init(store: StoreOf<RecoveryPhraseDisplay>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    let groups = store.phrase.toGroups(groupSizeOverride: 3)

                    NighthawkLogo(spacing: .compact, showsTitle: false)
                        .padding(.bottom, 25)

                    instructions

                    if isCaptured {
                        // When screen is being captured/recorded, hide the seed
                        Text("Screen recording or screenshot detected.\nSeed phrase hidden for security.")
                            .caption(color: Asset.Colors.Nighthawk.peach.color)
                            .multilineTextAlignment(.center)
                            .padding(.top, 25)
                            .padding(.horizontal, 16)
                    } else {
                        SeedView(groups: groups, birthday: store.birthday)
                            .padding(.top, 25)
                    }

                    if store.flow == .settings {
                        actions()
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 22)
                .padding(.bottom, 24)
            }

            if store.flow == .onboarding {
                onboardingFooter
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { store.send(.onAppear) }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            isCaptured = UIScreen.main.isCaptured
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            // Screenshot already taken — we can't prevent it, but we can
            // hide the seed going forward so repeated screenshots fail.
            isCaptured = true
            // Re-show after a short delay so the user can continue
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isCaptured = UIScreen.main.isCaptured
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .privacySensitive()
        .applyNighthawkBackground()
        .nighthawkAlert(
            store: store.scope(
                state: \.$destination.exportSeedAlert,
                action: \.destination.exportSeedAlert
            )
        ) { store in
            ExportSeedView(store: store)
        }
    }
}

// MARK: - Subviews
private extension RecoveryPhraseDisplayView {
    @ViewBuilder
    var instructions: some View {
        Text(L10n.Nighthawk.RecoveryPhraseDisplay.title)
            .paragraphMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
            .frame(maxWidth: .infinity, alignment: .leading)

        Text(L10n.Nighthawk.RecoveryPhraseDisplay.instructions1)
            .caption(color: .white)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 11)

        Text(L10n.Nighthawk.RecoveryPhraseDisplay.instructions2)
            .caption(color: .white)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 11)
    }

    /// Checkbox + Continue stay on-screen. A previous full-screen overlay sat on top of
    /// those controls (`allowsHitTesting(false)`), so taps hit the disabled Continue
    /// button instead of the checkbox — Continue appeared to do nothing.
    var onboardingFooter: some View {
        VStack(spacing: 16) {
            confirmPhrase(isChecked: $store.isConfirmSeedPhraseWrittenChecked)
                .disabled(store.isOpeningWallet)

            if store.isOpeningWallet {
                ProgressView()
                    .tint(Asset.Colors.Nighthawk.peach.color)
                Text("Opening wallet…")
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
            }

            actions()
        }
        .padding(.horizontal, 25)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Asset.Colors.Nighthawk.navy.color)
    }

    func confirmPhrase(isChecked: Binding<Bool>) -> some View {
        CheckBox(isChecked: isChecked) {
            Text(L10n.Nighthawk.RecoveryPhraseDisplay.confirmPhraseWrittenDownCheckBox)
                .caption()
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("recoveryPhraseConfirmCheckbox")
    }

    @MainActor
    func actions() -> some View {
        Group {
            if store.flow == .settings {
                Button(L10n.Nighthawk.RecoveryPhraseDisplay.exportAsPdf) {
                    store.send(.exportAsPdfPressed, animation: .easeInOut)
                }
                .buttonStyle(.nighthawkPrimary(width: 218))
            } else {
                Button(L10n.Nighthawk.RecoveryPhraseDisplay.continue) {
                    store.send(.continuePressed)
                }
                .buttonStyle(.nighthawkPrimary(width: 152))
                .disabled(!store.isConfirmSeedPhraseWrittenChecked || store.isOpeningWallet)
                .accessibilityIdentifier("recoveryPhraseContinue")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
