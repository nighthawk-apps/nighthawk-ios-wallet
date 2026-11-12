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
import UIKit
import Utils

public struct RecoveryPhraseDisplayView: View {
    @Bindable var store: StoreOf<RecoveryPhraseDisplay>
    @State private var isCaptured = false

    public init(store: StoreOf<RecoveryPhraseDisplay>) {
        self.store = store
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                let groups = store.phrase.toGroups(groupSizeOverride: 3)

                // Android SeedBackup: Spacer(44.dp) — no in-app logo; wallpaper
                // wordmark clearance only.
                Color.clear
                    .frame(height: NighthawkLogo.wordmarkClearance)
                    .frame(maxWidth: .infinity)

                instructions

                if isCaptured {
                    Text("Screen recording or screenshot detected.\nSeed phrase hidden for security.")
                        .caption(color: CyberpunkPalette.primary)
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
                } else {
                    // Checkbox + Continue live in the scroll (Android SeedBackup
                    // parity). A sticky navy footer made the checkbox hard to
                    // hit in the simulator and left Continue looking permanently
                    // disabled.
                    onboardingConfirmAndContinue
                        .padding(.top, 24)
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 22)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { store.send(.onAppear) }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            isCaptured = ScreenCapture.isCaptured
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            isCaptured = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isCaptured = ScreenCapture.isCaptured
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
    @ViewBuilder var instructions: some View {
        Text(L10n.Nighthawk.RecoveryPhraseDisplay.title)
            .paragraphMedium(color: CyberpunkPalette.muted)
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

    var onboardingConfirmAndContinue: some View {
        VStack(spacing: 16) {
            confirmPhrase(isChecked: $store.isConfirmSeedPhraseWrittenChecked)
                .disabled(store.isOpeningWallet)

            if store.isOpeningWallet {
                ProgressView()
                    .tint(CyberpunkPalette.primary)
                Text("Opening wallet…")
                    .caption(color: CyberpunkPalette.muted)
            }

            actions()
        }
        .frame(maxWidth: .infinity)
    }

    func confirmPhrase(isChecked: Binding<Bool>) -> some View {
        Button {
            isChecked.wrappedValue.toggle()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isChecked.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(
                        isChecked.wrappedValue
                            ? CyberpunkPalette.primary
                            : Color.white
                    )
                    .frame(width: 28, height: 28)

                Text(L10n.Nighthawk.RecoveryPhraseDisplay.confirmPhraseWrittenDownCheckBox)
                    .caption()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recoveryPhraseConfirmCheckbox")
        .accessibilityAddTraits(.isButton)
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
