//
//  NighthawkSetting.swift
//
//
//  Created by Matthew Watt on 8/3/23.
//

import Foundation
import Generated
import SwiftUI

public enum NighthawkSetting {
    /// Network for wallet traffic (lightwalletd sync and broadcast). Chat P2P keeps its own Tor
    /// Network for the whole app: wallet, chat, and node traffic.
    public enum PrivacyNetwork: String, CaseIterable, Identifiable, Hashable {
        case nym
        case tor
        case direct

        public static let `default`: PrivacyNetwork = .nym
        public static let nymSocksPort: UInt16 = 1080

        public var id: String { rawValue }

        public var chatLabel: String {
            switch self {
            case .nym: return "Nym"
            case .tor: return "Tor"
            case .direct: return "Direct"
            }
        }
    }

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

    public enum Theme: String, CaseIterable, Equatable, Identifiable, Hashable {
        case `default`
        case dark
        case light
        case paper
        case midnight
        case cyberpunk

        public static var allCases: [Theme] {
            [.cyberpunk, .dark, .midnight, .light, .paper]
        }

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .`default`, .cyberpunk:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.cyberpunk
            case .dark:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.dark
            case .light:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.light
            case .paper:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.paper
            case .midnight:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.midnight
            }
        }

        /// Cyberpunk stays dark. A light system theme does not switch it to Paper.
        public var colorScheme: ColorScheme? {
            switch self {
            case .paper, .light:
                .light
            case .dark, .midnight, .cyberpunk, .default:
                .dark
            }
        }

        /// System default and the Cyberpunk choice. Light and dark system
        /// appearances both use the Void wallpaper.
        public var usesCyberpunkChrome: Bool {
            self == .default || self == .cyberpunk
        }

        public var usesPaperTypography: Bool {
            self == .paper
        }

        /// Dynamic token set. Paper and Dark keep the asset catalog.
        public var paletteOverride: ColorAsset.PaletteOverride {
            switch self {
            case .default, .cyberpunk:
                .cyberpunk
            case .light:
                .light
            case .midnight:
                .midnight
            case .dark, .paper:
                .none
            }
        }

        public var primaryAccentColor: Color {
            switch self {
            case .default, .cyberpunk:
                Color(red: 0x5C / 255, green: 0xE1 / 255, blue: 0xFF / 255)
            case .midnight:
                Color(red: 0x9B / 255, green: 0x87 / 255, blue: 0xF5 / 255)
            case .light:
                Color(red: 0x2C / 255, green: 0x33 / 255, blue: 0x3A / 255)
            case .dark, .paper:
                Asset.Colors.Nighthawk.peach.color
            }
        }

        public var onPrimaryAccentColor: Color {
            switch self {
            case .default, .cyberpunk:
                return Color(red: 0x04 / 255, green: 0x10 / 255, blue: 0x18 / 255)
            case .midnight:
                return Color(red: 0x0B / 255, green: 0x08 / 255, blue: 0x16 / 255)
            case .light:
                return Color(red: 0xF7 / 255, green: 0xF8 / 255, blue: 0xFA / 255)
            case .paper:
                return .white
            case .dark:
                return Color(red: 0x08 / 255, green: 0x10 / 255, blue: 0x18 / 255)
            }
        }

        public var secondaryContainerColor: Color {
            switch self {
            case .default, .cyberpunk:
                return Color(red: 0x6B / 255, green: 0x1A / 255, blue: 0x6B / 255)
            case .midnight:
                return Color(red: 0x2C / 255, green: 0x35 / 255, blue: 0x45 / 255)
            case .light:
                return Color(red: 0xC9 / 255, green: 0xD2 / 255, blue: 0xDC / 255)
            case .paper:
                return Color(red: 0xE6 / 255, green: 0xE9 / 255, blue: 0xED / 255)
            case .dark:
                return Color(red: 0x24 / 255, green: 0x30 / 255, blue: 0x38 / 255)
            }
        }

        public var secondaryAccentColor: Color {
            switch self {
            case .default, .cyberpunk:
                return Color(red: 0xC9 / 255, green: 0x4B / 255, blue: 0xB8 / 255)
            case .midnight:
                return Color(red: 0xB8 / 255, green: 0xA8 / 255, blue: 0xFF / 255)
            case .light:
                return Color(red: 0x5C / 255, green: 0x65 / 255, blue: 0x70 / 255)
            case .paper:
                return Color(red: 0x5E / 255, green: 0x6A / 255, blue: 0x74 / 255)
            case .dark:
                return Color(red: 0x5E / 255, green: 0x9B / 255, blue: 0xAF / 255)
            }
        }

        public var onSecondaryContainerColor: Color {
            if usesCyberpunkChrome {
                return Color(red: 0xFF / 255, green: 0xD6 / 255, blue: 0xF6 / 255)
            }
            return Asset.Colors.Nighthawk.textHeader.color
        }

        public var statusSuccessColor: Color {
            switch self {
            case .paper, .light:
                Color(red: 0x1E / 255, green: 0x7E / 255, blue: 0x52 / 255)
            case .dark, .midnight, .cyberpunk, .default:
                Color(red: 0x3D / 255, green: 0xDC / 255, blue: 0x97 / 255)
            }
        }

        public var statusWarningColor: Color {
            switch self {
            case .paper, .light:
                Color(red: 0xB2 / 255, green: 0x6A / 255, blue: 0x00 / 255)
            case .dark, .midnight, .cyberpunk, .default:
                Color(red: 0xFF / 255, green: 0xB3 / 255, blue: 0x40 / 255)
            }
        }

        public var statusDangerColor: Color {
            Asset.Colors.Nighthawk.error.color
        }
    }
}

public extension Notification.Name {
    static let nighthawkThemeDidChange = Notification.Name("nighthawkThemeDidChange")
}

/// Observed by the root view so a theme change repaints without restarting.
public final class NighthawkThemeController: ObservableObject {
    public static let shared = NighthawkThemeController()

    @Published public private(set) var theme: NighthawkSetting.Theme {
        didSet {
            ColorAsset.paletteOverride = theme.paletteOverride
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "darkfiTheme") ?? NighthawkSetting.Theme.default.rawValue
        let initial = NighthawkSetting.Theme(rawValue: raw) ?? .default
        ColorAsset.paletteOverride = initial.paletteOverride
        theme = initial
        NotificationCenter.default.addObserver(
            forName: .nighthawkThemeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let raw = note.object as? String,
                  let next = NighthawkSetting.Theme(rawValue: raw) else { return }
            ColorAsset.paletteOverride = next.paletteOverride
            self?.theme = next
        }
    }
}
