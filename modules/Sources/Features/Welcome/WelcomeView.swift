//
//  WelcomeView.swift
//  secant-testnet
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import Generated
import ImportWarning
import SwiftUI
import UIComponents

public struct WelcomeView: View {
    let store: StoreOf<Welcome>
    
    public init(store: StoreOf<Welcome>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                NighthawkLogo()
                    .padding(.top, 44)
                Spacer()
                mainContent()
                Spacer()
                terms {
                    viewStore.send(.termsAndConditionsTapped)
                }
                Spacer()
                actions {
                    viewStore.send(
                        .createNewWalletTapped,
                        animation: .easeInOut(duration: 0.8)
                    )
                } onRestore: {
                    viewStore.send(
                        .importExistingWalletTapped,
                        animation: .easeInOut
                    )
                }
            }
            .applyNighthawkBackground()
        }
        .nighthawkAlert(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /Welcome.Destination.State.importSeedWarningAlert,
            action: Welcome.Destination.Action.importSeedWarningAlert
        ) { store in
            ImportWarningView(store: store)
        }
    }
}

// MARK: - Subviews
private extension WelcomeView {
    @ViewBuilder func mainContent() -> some View {
        Text(L10n.Nighthawk.Welcome.subtitle)
            .subtitle()
            .padding(.bottom, 15)
        
        Text(L10n.Nighthawk.Welcome.body)
            .paragraph()
            .lineSpacing(10)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 58)
    }
    
    func terms(
        onTermsLinkTapped: @escaping () -> Void
    ) -> some View {
        VStack {
            Text(L10n.Nighthawk.Welcome.terms1)
                .caption()
                .padding(.bottom, 4)
            
            Button(L10n.Nighthawk.Welcome.terms2, action: onTermsLinkTapped)
                .buttonStyle(.nighthawkLink())
        }
    }
    
    func actions(
        onCreate: @escaping () -> Void,
        onRestore: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Button(L10n.Nighthawk.Welcome.create, action: onCreate)
            .buttonStyle(.nighthawkPrimary())
            
            Button(L10n.Nighthawk.Welcome.restore, action: onRestore)
            .buttonStyle(.nighthawkSecondary())
        }
        .padding(.bottom, 64)
    }
}

