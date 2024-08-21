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
    @Bindable var store: StoreOf<RecoveryPhraseDisplay>
    
    public init(store: StoreOf<RecoveryPhraseDisplay>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            Group {
                let groups = store.phrase.toGroups(groupSizeOverride: 3)
                
                instructions
                
                SeedView(groups: groups, birthday: store.birthday)
                
                if store.flow == .onboarding {
                    confirmPhrase(isChecked: $store.isConfirmSeedPhraseWrittenChecked)
                }
                
                Spacer()
                
                actions(groups: groups)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 25)
        .padding(.horizontal, 25)
        .padding(.bottom, 66)
        .onAppear { store.send(.onAppear) }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .applyNighthawkBackground()
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
                .disabled(!store.state.isConfirmSeedPhraseWrittenChecked)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

