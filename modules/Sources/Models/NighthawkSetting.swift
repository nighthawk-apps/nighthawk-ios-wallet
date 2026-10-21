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

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .`default`:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.default
            case .dark:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.dark
            case .paper:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.paper
            }
        }

        /// `nil` follows the system. A light system uses Paper; a dark system uses Stealth.
        public var colorScheme: ColorScheme? {
            switch self {
            case .paper:
                .light
            case .dark:
                .dark
            case .default:
                nil
            }
        }

        public var usesPaperTypography: Bool {
            self == .paper
        }
    }
}

public extension Notification.Name {
    static let nighthawkThemeDidChange = Notification.Name("nighthawkThemeDidChange")
}

/// Observed by the root view so a theme change repaints without restarting.
public final class NighthawkThemeController: ObservableObject {
    public static let shared = NighthawkThemeController()

    @Published public private(set) var theme: NighthawkSetting.Theme

    private init() {
        let raw = UserDefaults.standard.string(forKey: "darkfiTheme") ?? NighthawkSetting.Theme.default.rawValue
        theme = NighthawkSetting.Theme(rawValue: raw) ?? .default
        NotificationCenter.default.addObserver(
            forName: .nighthawkThemeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let raw = note.object as? String,
                  let next = NighthawkSetting.Theme(rawValue: raw) else { return }
            self?.theme = next
        }
    }
}
