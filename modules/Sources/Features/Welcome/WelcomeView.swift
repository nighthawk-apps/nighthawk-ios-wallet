//
//  WelcomeView.swift
//  stealth
//
//  Created by Matthew Watt on 9/11/23.
//

import ComposableArchitecture
import Generated
import ImportWarning
import SwiftUI
import UIComponents

public struct WelcomeView: View {
    @Bindable var store: StoreOf<Welcome>
    @State private var currentPage = 0
    
    public init(store: StoreOf<Welcome>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            NighthawkLogo()
                .padding(.top, 44)
            
            Spacer()
            
            // Onboarding carousel (matches Android OnboardingCarousel)
            onboardingCarousel
            
            Spacer()
            
            terms {
                store.send(.termsAndConditionsTapped)
            }
            .padding(.bottom, 16)
            
            actions {
                store.send(.createNewWalletTapped)
            } onRestore: {
                store.send(.importExistingWalletTapped)
            }
        }
        .applyNighthawkBackground()
        .nighthawkAlert(
            store: store.scope(
                state: \.$destination.importSeedWarningAlert,
                action: \.destination.importSeedWarningAlert
            )
        ) { store in
            ImportWarningView(store: store)
        }
    }
}

// MARK: - Onboarding Carousel
private extension WelcomeView {
    struct OnboardingPage: Identifiable {
        let id: Int
        let icon: String // SF Symbol
        let title: String
        let description: String
    }
    
    static var onboardingPages: [OnboardingPage] {
        [
            OnboardingPage(
                id: 0,
                icon: "shield.lefthalf.filled",
                title: L10n.Nighthawk.Welcome.Carousel.title1,
                description: L10n.Nighthawk.Welcome.Carousel.body1
            ),
            OnboardingPage(
                id: 1,
                icon: "network",
                title: L10n.Nighthawk.Welcome.Carousel.title2,
                description: L10n.Nighthawk.Welcome.Carousel.body2
            ),
            OnboardingPage(
                id: 2,
                icon: "bubble.left.and.bubble.right.fill",
                title: L10n.Nighthawk.Welcome.Carousel.title3,
                description: L10n.Nighthawk.Welcome.Carousel.body3
            )
        ]
    }
    
    var onboardingCarousel: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentPage) {
                ForEach(Self.onboardingPages) { page in
                    carouselPage(page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 240)
            .clipped()
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            // Page indicators (matches Android dot indicators)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index
                              ? Asset.Colors.Nighthawk.peach.color
                              : Color.white.opacity(0.3))
                        .frame(width: currentPage == index ? 10 : 7,
                               height: currentPage == index ? 10 : 7)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    func carouselPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: 16) {
            Image(systemName: page.icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Asset.Colors.Nighthawk.peach.color,
                            Asset.Colors.Nighthawk.peach.color.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 88, height: 88)
                )
                .padding(.bottom, 8)
            
            Text(page.title)
                .subtitle()
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .paragraph()
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
}

// MARK: - Subviews
private extension WelcomeView {
    func terms(
        onTermsLinkTapped: @escaping () -> Void
    ) -> some View {
        VStack {
            Text(L10n.Nighthawk.Welcome.terms1)
                .caption()
                .padding(.bottom, 4)
            
            Button(L10n.General.termsAndConditions, action: onTermsLinkTapped)
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
