//
//  NHRecoveryPhraseDisplayView.swift
//  stealth
//
//  Created by Matthew Watt on 3/24/23.
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
        ZStack {
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

                    if store.flow == .onboarding {
                        confirmPhrase(isChecked: $store.isConfirmSeedPhraseWrittenChecked)
                            .padding(.top, 20)
                    }

                    actions(groups: groups)
                        .padding(.top, 24)
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 22)
            .padding(.bottom, 66)

            if store.flow == .onboarding, !store.isConfirmSeedPhraseWrittenChecked {
                backupConfirmationBlocker
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

    func confirmPhrase(isChecked: Binding<Bool>) -> some View {
        CheckBox(isChecked: isChecked) {
            Text(L10n.Nighthawk.RecoveryPhraseDisplay.confirmPhraseWrittenDownCheckBox)
                .caption()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var backupConfirmationBlocker: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)

                Text("Write down all 22 words before continuing")
                    .subtitleMedium(color: .white)
                    .multilineTextAlignment(.center)

                Text("Check the box below to confirm you have saved your recovery phrase in a safe place.")
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Asset.Colors.Nighthawk.darkNavy.color.opacity(0.95))
            )
            .padding(.horizontal, 25)
            .padding(.bottom, 140)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.45).ignoresSafeArea())
        .allowsHitTesting(false)
    }

    @MainActor
    func actions(groups: [RecoveryPhrase.Group]) -> some View {
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
                .disabled(!store.isConfirmSeedPhraseWrittenChecked)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
