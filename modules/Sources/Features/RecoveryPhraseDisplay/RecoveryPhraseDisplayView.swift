//
//  NHRecoveryPhraseDisplayView.swift
//  secant
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
import ZcashLightClientKit

public struct RecoveryPhraseDisplayView: View {
    let store: StoreOf<RecoveryPhraseDisplay>
    
    public init(store: StoreOf<RecoveryPhraseDisplay>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Group {
                    let groups = viewStore.phrase.toGroups(groupSizeOverride: 3)
                    
                    instructions
                    
                    SeedView(groups: groups, birthday: viewStore.birthday)
                    
                    if viewStore.flow == .onboarding {
                        confirmPhrase(isChecked: viewStore.$isConfirmSeedPhraseWrittenChecked)
                    }
                    
                    Spacer()
                    
                    actions(groups: groups, viewStore: viewStore)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 25)
            .padding(.horizontal, 25)
            .padding(.bottom, 66)
            .onAppear { viewStore.send(.onAppear) }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .applyNighthawkBackground()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .nighthawkAlert(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /RecoveryPhraseDisplay.Destination.State.exportSeedAlert,
            action: RecoveryPhraseDisplay.Destination.Action.exportSeedAlert
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
            .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
        
        Text(L10n.Nighthawk.RecoveryPhraseDisplay.instructions1)
            .paragraphMedium(color: .white)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)
        
        Text(L10n.Nighthawk.RecoveryPhraseDisplay.instructions2)
            .paragraphMedium(color: .white)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)
    }
    
    func confirmPhrase(isChecked: Binding<Bool>) -> some View {
        CheckBox(isChecked: isChecked) {
            Text(L10n.Nighthawk.RecoveryPhraseDisplay.confirmPhraseWrittenDownCheckBox)
                .caption()
        }
        .frame(maxWidth: .infinity)
    }
    
    @MainActor
    func actions(groups: [RecoveryPhrase.Group], viewStore: ViewStoreOf<RecoveryPhraseDisplay>) -> some View {
        Group {
            if viewStore.flow == .settings {
                Button(L10n.Nighthawk.RecoveryPhraseDisplay.exportAsPdf) {
                    viewStore.send(.exportAsPdfPressed, animation: .easeInOut)
                }
                .buttonStyle(.nighthawkPrimary(width: 218))
            } else {
                Button(L10n.Nighthawk.RecoveryPhraseDisplay.continue) {
                    viewStore.send(.continuePressed)
                }
                .buttonStyle(.nighthawkPrimary(width: 152))
                .disabled(!viewStore.state.isConfirmSeedPhraseWrittenChecked)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

