//
//  NHPlainOnboardingView.swift
//  secant
//
//  Created by Matthew Watt on 3/22/23.
//

import ComposableArchitecture
import Generated
import NHImportWallet
import SwiftUI
import UIComponents
import WalletCreated

public struct NHPlainOnboardingView: View {
    let store: OnboardingFlowStore
    
    public init(store: OnboardingFlowStore) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                NighthawkLogo()
                    .padding(.top, 44)
                Spacer()
                mainContent()
                Spacer()
                terms {
                    viewStore.send(.termsAndConditions)
                }
                Spacer()
                actions {
                    viewStore.send(
                        .createNewWallet,
                        animation: .easeInOut(duration: 0.8)
                    )
                } onRestore: {
                    viewStore.send(
                        .importExistingWallet,
                        animation: .easeInOut(duration: 0.8)
                    )
                }
            }
            .applyNighthawkBackground()
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.createNewWallet),
                destination: {
                    WalletCreatedView(
                        store: store.scope(
                            state: \.walletCreatedState,
                            action: OnboardingFlowReducer.Action.walletCreated
                        )
                    )
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.nhImportExistingWallet),
                destination: {
                    NHImportWalletView(
                        store: store.scope(
                            state: \.nhImportWalletState,
                            action: OnboardingFlowReducer.Action.nhImportWallet
                        )
                    )
                }
            )
            .navigationBarTitle(Text(""))
        }
    }
}

// MARK: - Subviews
private extension NHPlainOnboardingView {
    @ViewBuilder func mainContent() -> some View {
        Text(L10n.Nighthawk.PlainOnboarding.subtitle)
            .subtitle()
            .padding(.bottom, 15)
        
        Text(L10n.Nighthawk.PlainOnboarding.body)
            .paragraph()
            .lineSpacing(10)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 58)
    }
    
    func terms(
        onTermsLinkTapped: @escaping () -> Void
    ) -> some View {
        VStack {
            Text(L10n.Nighthawk.PlainOnboarding.terms1)
                .caption()
                .padding(.bottom, 4)
            
            Button(L10n.Nighthawk.PlainOnboarding.terms2, action: onTermsLinkTapped)
                .buttonStyle(.nighthawkLink())
        }
    }
    
    func actions(
        onCreate: @escaping () -> Void,
        onRestore: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Button(L10n.Nighthawk.PlainOnboarding.create, action: onCreate)
            .buttonStyle(.nighthawkPrimary())
            
            Button(L10n.Nighthawk.PlainOnboarding.restore, action: onRestore)
            .buttonStyle(.nighthawkSecondary())
        }
        .padding(.bottom, 64)
    }
}
