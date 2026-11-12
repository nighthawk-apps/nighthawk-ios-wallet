//
//  NighthawkSetting.swift
//

import Foundation
import Generated
import SwiftUI

public enum NighthawkSetting {
    public enum ScreenMode: String, CaseIterable, Identifiable, Hashable {
        case keepOn
        case off

        public var id: String { rawValue }
    }

    public enum SyncNotificationFrequency: String, CaseIterable, Identifiable, Hashable {
        case weekly
        case monthly
        case off

        public var id: String { rawValue }
    }

    public enum FiatCurrency: String, CaseIterable, Equatable, Identifiable, Hashable {
        case usd
        case eur
        case inr
        case jpy
        case gbp
        case cad
        case aud
        case hkd
        case sgd
        case chf
        case cny
        case krw
        case off

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .usd:
                L10n.Nighthawk.SettingsTab.FiatCurrency.usd
            case .eur:
                L10n.Nighthawk.SettingsTab.FiatCurrency.eur
            case .inr:
                L10n.Nighthawk.SettingsTab.FiatCurrency.inr
            case .jpy:
                L10n.Nighthawk.SettingsTab.FiatCurrency.jpy
            case .gbp:
                L10n.Nighthawk.SettingsTab.FiatCurrency.gbp
            case .cad:
                L10n.Nighthawk.SettingsTab.FiatCurrency.cad
            case .aud:
                L10n.Nighthawk.SettingsTab.FiatCurrency.aud
            case .hkd:
                L10n.Nighthawk.SettingsTab.FiatCurrency.hkd
            case .sgd:
                L10n.Nighthawk.SettingsTab.FiatCurrency.sgd
            case .chf:
                L10n.Nighthawk.SettingsTab.FiatCurrency.chf
            case .cny:
                L10n.Nighthawk.SettingsTab.FiatCurrency.cny
            case .krw:
                L10n.Nighthawk.SettingsTab.FiatCurrency.krw
            case .off:
                L10n.Nighthawk.SettingsTab.FiatCurrency.off
            }
        }
    }

    public enum AppIcon: String, CaseIterable, Equatable, Identifiable, Hashable {
        case `default` = "AppIcon"
        case retro = "RetroAppIcon"

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .`default`:
                L10n.Nighthawk.SettingsTab.Advanced.AppIcon.default
            case .retro:
                L10n.Nighthawk.SettingsTab.Advanced.AppIcon.retro
            }
        }

        public var preview: Image {
            switch self {
            case .`default`:
                Asset.Assets.Icons.Nighthawk.defaultIconPreview.image
            case .retro:
                Asset.Assets.Icons.Nighthawk.retroIconPreview.image
            }
        }
    }

    /// Matches Android `AppThemeVariant`. Cyberpunk is the fresh-install default.
    public enum Theme: String, CaseIterable, Equatable, Identifiable, Hashable {
        case cyberpunk
        case stealth
        case light
        case paper
        case midnight
        /// Legacy storage values — migrated by `UserPreferencesStorage.theme`.
        case `default`
        case dark

        public var id: String { rawValue }

        /// Themes shown in Advanced settings (legacy cases hidden).
        public static var selectableCases: [Theme] {
            [.cyberpunk, .stealth, .light, .paper, .midnight]
        }

        public var label: String {
            switch self {
            case .cyberpunk, .`default`:
                "Cyberpunk"
            case .stealth, .dark:
                "Stealth"
            case .light:
                "Light"
            case .paper:
                "Paper"
            case .midnight:
                "Midnight"
            }
        }

        /// Canonical theme after migrating legacy `default` / `dark` storage values.
        public var canonical: Theme {
            switch self {
            case .`default`: return .cyberpunk
            case .dark: return .stealth
            default: return self
            }
        }

        public var usesCyberpunkWallpaper: Bool {
            canonical == .cyberpunk
        }

        public var colorScheme: ColorScheme {
            switch canonical {
            case .light, .paper:
                return .light
            default:
                return .dark
            }
        }
    }
}
