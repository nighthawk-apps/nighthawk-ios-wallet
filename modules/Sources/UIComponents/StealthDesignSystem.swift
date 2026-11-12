//
//  StealthDesignSystem.swift
//  stealth
//
//  Design system matching Android's WalletTheme + StealthTokens.
//  Provides centralized color and typography tokens for the entire app.
//
//  Android mapping:
//    PulpDisplay  → Orbitron (headings, titles, buttons)
//    ShareTechMono → Share Tech Mono (body text, labels, data)
//    Rubik        → Rubik (UI chrome, navigation)
//

import SwiftUI
import Generated

// MARK: - StealthTheme

/// Centralized theme matching Android's `WalletTheme.colors` and `Typography`.
public enum StealthTheme {
    // ── Typography ──────────────────────────────────────────────────

    /// Heading font (Orbitron on Android, PulpDisplay on iOS)
    public enum Heading {
        public static func bold(_ size: CGFloat) -> Font {
            .custom(FontFamily.PulpDisplay.bold.name, size: size)
        }
        public static func medium(_ size: CGFloat) -> Font {
            .custom(FontFamily.PulpDisplay.medium.name, size: size)
        }
        public static func regular(_ size: CGFloat) -> Font {
            .custom(FontFamily.PulpDisplay.regular.name, size: size)
        }

        // Named styles matching Android Typography
        public static let headlineLarge = Font.custom(FontFamily.PulpDisplay.bold.name, size: 30)
        public static let headlineMedium = Font.custom(FontFamily.PulpDisplay.regular.name, size: 28)
        public static let titleLarge = Font.custom(FontFamily.PulpDisplay.regular.name, size: 21)
        public static let titleMedium = Font.custom(FontFamily.PulpDisplay.regular.name, size: 16)
        public static let titleSmall = Font.custom(FontFamily.PulpDisplay.regular.name, size: 12)
    }

    /// Body/data font (Share Tech Mono on Android, Rubik on iOS)
    public enum Body {
        public static func regular(_ size: CGFloat) -> Font {
            .custom(FontFamily.Rubik.regular.name, size: size)
        }
        public static func medium(_ size: CGFloat) -> Font {
            .custom(FontFamily.Rubik.medium.name, size: size)
        }
        public static func semiBold(_ size: CGFloat) -> Font {
            .custom(FontFamily.Rubik.semiBold.name, size: size)
        }

        // Named styles matching Android Typography
        public static let bodyLarge = Font.custom(FontFamily.Rubik.regular.name, size: 16)
        public static let bodyMedium = Font.custom(FontFamily.Rubik.regular.name, size: 14)
        public static let bodySmall = Font.custom(FontFamily.Rubik.regular.name, size: 12)
        public static let labelLarge = Font.custom(FontFamily.Rubik.regular.name, size: 16)
    }

    /// Monospace font for addresses, hashes, keys
    public enum Mono {
        public static func regular(_ size: CGFloat) -> Font {
            .system(size: size, design: .monospaced)
        }
    }

    /// Balance display font
    public static let drkBalance = Font.custom(FontFamily.PulpDisplay.regular.name, size: 30)

    // ── Colors ──────────────────────────────────────────────────────

    public enum Colors {
        /// Cyberpunk wallpaper letterbox. Panels stay translucent so the
        /// wallpaper shows through, matching Android `LocalCyberpunkChrome`.
        public static var backgroundStart: Color { CyberpunkPalette.backdrop }
        public static var backgroundEnd: Color { CyberpunkPalette.backdrop }
        public static var surface: Color { CyberpunkPalette.surface }
        public static var surfaceVariant: Color { CyberpunkPalette.surfaceVariant }

        public static var primary: Color { CyberpunkPalette.primary }
        public static var primaryPressed: Color { CyberpunkPalette.primary.opacity(0.8) }
        public static var primaryDeep: Color { CyberpunkPalette.onPrimary }
        public static var primaryMuted: Color { CyberpunkPalette.primary.opacity(0.45) }

        public static var textHeader: Color { CyberpunkPalette.header }
        public static var textBody: Color { CyberpunkPalette.body }
        public static var textMuted: Color { CyberpunkPalette.muted }

        public static var border: Color { CyberpunkPalette.outline }
        public static var borderMuted: Color { CyberpunkPalette.outline.opacity(0.6) }

        public static var secondaryFill: Color { CyberpunkPalette.tertiaryFill }

        public static var dangerous: Color { Asset.Colors.Nighthawk.dangerous.color }

        public static var callout: Color { CyberpunkPalette.surfaceVariant }
        public static var onCallout: Color { CyberpunkPalette.body }
    }
}

// MARK: - View Modifiers

public extension View {
    /// Cyberpunk wallpaper. Same treatment as `applyNighthawkBackground()`.
    func stealthBackground() -> some View {
        applyNighthawkBackground()
    }
}
