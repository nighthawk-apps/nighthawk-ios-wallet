//
//  WelcomeView.swift
//  stealth
//

import ComposableArchitecture
import Generated
import ImportWarning
import SwiftUI
import UIComponents

public struct WelcomeView: View {
    @Bindable var store: StoreOf<Welcome>
    @State private var currentPage: Int? = 0

    public init(store: StoreOf<Welcome>) {
        self.store = store
    }

    public var body: some View {
        Group {
            switch store.mode {
            case .getStarted:
                getStartedContent
            case .postBackupCarousel:
                carouselContent
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

// MARK: - Get started (create / restore)
private extension WelcomeView {
    var getStartedContent: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Android leaves the wallpaper's NIGHTHAWK mark in the top
                // corner and starts the copy about a tenth of the way down.
                Spacer().frame(height: geo.size.height * 0.10)

                Text(L10n.Nighthawk.Welcome.subtitle)
                    .subtitleMedium(color: CyberpunkPalette.header)
                    .multilineTextAlignment(.center)

                Text(L10n.Nighthawk.Welcome.body)
                    .paragraph(color: CyberpunkPalette.body)
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: geo.size.width * 0.7)
                    .padding(.top, 16)

                Text(L10n.Nighthawk.Welcome.footer)
                    .caption(color: CyberpunkPalette.tagline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: geo.size.width * 0.7)
                    .padding(.top, 64)

                Spacer(minLength: 0)

                actions {
                    store.send(.createNewWalletTapped)
                } onRestore: {
                    store.send(.importExistingWalletTapped)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Post-backup onboarding carousel
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

    var carouselContent: some View {
        VStack(spacing: 0) {
            NighthawkLogo(size: .tabHeader)
                .padding(.top, 16)

            Spacer(minLength: 0)

            onboardingCarousel

            Spacer(minLength: 0)

            Button(carouselPrimaryTitle) {
                if isLastCarouselPage {
                    store.send(.carouselFinished)
                } else {
                    let next = min(Self.onboardingPages.count - 1, (currentPage ?? 0) + 1)
                    currentPage = next
                }
            }
            .buttonStyle(.nighthawkPrimary(width: 210))
            .padding(.bottom, 64)
            .accessibilityIdentifier("nighthawk.welcome.carousel.continue")
        }
    }

    var isLastCarouselPage: Bool {
        (currentPage ?? 0) >= Self.onboardingPages.count - 1
    }

    var carouselPrimaryTitle: String {
        isLastCarouselPage
            ? L10n.Nighthawk.RecoveryPhraseDisplay.continue
            : L10n.General.next
    }

    var onboardingCarousel: some View {
        VStack(spacing: 24) {
            // Page-style TabView installs a full-screen UIPageViewController gesture
            // layer that steals taps from the welcome buttons below it on device.
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(Self.onboardingPages) { page in
                        carouselPage(page)
                            .containerRelativeFrame(.horizontal)
                            .id(page.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentPage)
            .frame(height: 240)
            .clipped()
            .contentShape(Rectangle())

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            currentPage == index
                                ? CyberpunkPalette.primary
                                : Color.white.opacity(0.3)
                        )
                        .frame(
                            width: currentPage == index ? 10 : 7,
                            height: currentPage == index ? 10 : 7
                        )
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
                            CyberpunkPalette.primary,
                            CyberpunkPalette.primary.opacity(0.6)
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
    func actions(
        onCreate: @escaping () -> Void,
        onRestore: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Button(L10n.Nighthawk.Welcome.create, action: onCreate)
                .buttonStyle(.nighthawkPrimary(width: 210))
                .accessibilityIdentifier("nighthawk.welcome.create")

            Button(L10n.Nighthawk.Welcome.restore, action: onRestore)
                .buttonStyle(.nighthawkTertiary(width: 210))
                .accessibilityIdentifier("nighthawk.welcome.restore")
        }
        .padding(.bottom, 64)
    }
}
