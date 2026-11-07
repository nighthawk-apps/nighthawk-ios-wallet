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
        case paper
        case cyberpunk

        public static var allCases: [Theme] {
            [.cyberpunk, .dark, .paper]
        }

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .`default`, .cyberpunk:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.cyberpunk
            case .dark:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.dark
            case .paper:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.paper
            }
        }

        /// Cyberpunk stays dark. A light system theme does not switch it to Paper.
        public var colorScheme: ColorScheme? {
            switch self {
            case .paper:
                .light
            case .dark, .cyberpunk, .default:
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

        public var primaryAccentColor: Color {
            usesCyberpunkChrome
                ? Color(red: 0x5C / 255, green: 0xE1 / 255, blue: 0xFF / 255)
                : Asset.Colors.Nighthawk.peach.color
        }

        public var onPrimaryAccentColor: Color {
            if usesCyberpunkChrome {
                return Color(red: 0x04 / 255, green: 0x10 / 255, blue: 0x18 / 255)
            }
            return self == .paper
                ? .white
                : Color(red: 0x08 / 255, green: 0x10 / 255, blue: 0x18 / 255)
        }

        public var secondaryContainerColor: Color {
            if usesCyberpunkChrome {
                return Color(red: 0x6B / 255, green: 0x1A / 255, blue: 0x6B / 255)
            }
            return self == .paper
                ? Color(red: 0xE6 / 255, green: 0xE9 / 255, blue: 0xED / 255)
                : Color(red: 0x24 / 255, green: 0x30 / 255, blue: 0x38 / 255)
        }

        public var secondaryAccentColor: Color {
            if usesCyberpunkChrome {
                return Color(red: 0xC9 / 255, green: 0x4B / 255, blue: 0xB8 / 255)
            }
            return self == .paper
                ? Color(red: 0x5E / 255, green: 0x6A / 255, blue: 0x74 / 255)
                : Color(red: 0x5E / 255, green: 0x9B / 255, blue: 0xAF / 255)
        }

        public var onSecondaryContainerColor: Color {
            if usesCyberpunkChrome {
                return Color(red: 0xFF / 255, green: 0xD6 / 255, blue: 0xF6 / 255)
            }
            return Asset.Colors.Nighthawk.textHeader.color
        }

        public var statusSuccessColor: Color {
            self == .paper
                ? Color(red: 0x1E / 255, green: 0x7E / 255, blue: 0x52 / 255)
                : Color(red: 0x3D / 255, green: 0xDC / 255, blue: 0x97 / 255)
        }

        public var statusWarningColor: Color {
            self == .paper
                ? Color(red: 0xB2 / 255, green: 0x6A / 255, blue: 0x00 / 255)
                : Color(red: 0xFF / 255, green: 0xB3 / 255, blue: 0x40 / 255)
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
            ColorAsset.usesCyberpunkPalette = theme.usesCyberpunkChrome
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "darkfiTheme") ?? NighthawkSetting.Theme.default.rawValue
        let initial = NighthawkSetting.Theme(rawValue: raw) ?? .default
        ColorAsset.usesCyberpunkPalette = initial.usesCyberpunkChrome
        theme = initial
        NotificationCenter.default.addObserver(
            forName: .nighthawkThemeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let raw = note.object as? String,
                  let next = NighthawkSetting.Theme(rawValue: raw) else { return }
            ColorAsset.usesCyberpunkPalette = next.usesCyberpunkChrome
            self?.theme = next
        }
    }
}
