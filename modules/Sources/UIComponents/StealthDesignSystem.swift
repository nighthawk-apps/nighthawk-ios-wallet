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
        // Backgrounds (gradient: moonlit → charcoalDeep)
        public static var backgroundStart: Color { Asset.Colors.Nighthawk.moonlit.color }
        public static var backgroundEnd: Color { Asset.Colors.Nighthawk.charcoalDeep.color }
        public static var surface: Color { Asset.Colors.Nighthawk.charcoalRaised.color }
        public static var surfaceVariant: Color { Asset.Colors.Nighthawk.elevated.color }
        
        // Accent (teal)
        public static var primary: Color { Asset.Colors.Nighthawk.accent.color }
        public static var primaryPressed: Color { Asset.Colors.Nighthawk.accentPressed.color }
        public static var primaryDeep: Color { Asset.Colors.Nighthawk.accentDeep.color }
        public static var primaryMuted: Color { Asset.Colors.Nighthawk.accentMuted.color }
        
        // Text
        public static var textHeader: Color { Asset.Colors.Nighthawk.textHeader.color }
        public static var textBody: Color { Asset.Colors.Nighthawk.textBody.color }
        public static var textMuted: Color { Asset.Colors.Nighthawk.textMuted.color }
        
        // Borders
        public static var border: Color { Asset.Colors.Nighthawk.steelBorder.color }
        public static var borderMuted: Color { Asset.Colors.Nighthawk.steelBorderMuted.color }
        
        // Secondary fills
        public static var secondaryFill: Color { Asset.Colors.Nighthawk.secondaryFill.color }
        
        // Status
        public static var dangerous: Color { Asset.Colors.Nighthawk.dangerous.color }
        
        // Callout
        public static var callout: Color { Asset.Colors.Nighthawk.calloutFill.color }
        public static var onCallout: Color { Asset.Colors.Nighthawk.calloutOn.color }
    }
}

// MARK: - View Modifiers

public extension View {
    /// Apply the stealth gradient background matching Android's backgroundStart → backgroundEnd
    func stealthBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [StealthTheme.Colors.backgroundStart, StealthTheme.Colors.backgroundEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
