//
//  NHPlainOnboardingView.swift
//  secant
//
//  Created by Matthew Watt on 3/22/23.
//

import ComposableArchitecture
import SwiftUI

struct NHPlainOnboardingView: View {
    let store: OnboardingFlowStore
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                NighthawkLogo()
                    .padding(.top, 44)
                Spacer()
                mainContent()
                Spacer()
                terms()
                Spacer()
                actions {
                    viewStore.send(
                        .createNewWallet,
                        animation: .easeInOut(duration: 0.8)
                    )
                } onRestore: {
                    // todo
                }
            }
            .applyNighthawkBackground()
        }
    }
}

// MARK: - Subviews
private extension NHPlainOnboardingView {
    @ViewBuilder func mainContent() -> some View {
        Text(L10n.Nighthawk.PlainOnboarding.subtitle)
            .subtitle
            .padding(.bottom, 15)
        
        Text(L10n.Nighthawk.PlainOnboarding.body)
            .paragraph()
            .lineSpacing(10)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 58)
    }
    
    func terms() -> some View {
        VStack {
            Text(L10n.Nighthawk.PlainOnboarding.terms1)
                .caption()
                .padding(.bottom, 4)
            
            Text(L10n.Nighthawk.PlainOnboarding.terms2)
                .caption(color: Asset.Colors.Nighthawk.peach.color)
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
