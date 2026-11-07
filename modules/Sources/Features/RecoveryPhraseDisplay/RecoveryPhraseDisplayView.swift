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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isCaptured = UIScreen.main.isCaptured
            store.send(.onAppear)
        }
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
            .caption(color: Asset.Colors.Nighthawk.textHeader.color)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 11)

        Text(L10n.Nighthawk.RecoveryPhraseDisplay.instructions2)
            .caption(color: Asset.Colors.Nighthawk.textHeader.color)
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
