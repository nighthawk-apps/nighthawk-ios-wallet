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
    
    public enum LightwalletdServer: String, CaseIterable, Equatable, Identifiable, Hashable {
        case `default`
        case asiaOceania
        case europeAfrica
        case northAmerica
        case southAmerica
        
        public var id: String { rawValue }
        
        public var label: String {
            switch self {
            case .`default`:
                return L10n.Nighthawk.SettingsTab.ChangeServer.default
            case .asiaOceania:
                return L10n.Nighthawk.SettingsTab.ChangeServer.asiaOceania
            case .europeAfrica:
                return L10n.Nighthawk.SettingsTab.ChangeServer.europeAfrica
            case .northAmerica:
                return L10n.Nighthawk.SettingsTab.ChangeServer.northAmerica
            case .southAmerica:
                return L10n.Nighthawk.SettingsTab.ChangeServer.southAmerica
            }
        }
        
        public var host: String {
            switch self {
            case .`default`:
                return "mainnet.lightwalletd.com"
            case .asiaOceania:
                return "ai.lightwalletd.com"
            case .europeAfrica:
                return "eu.lightwalletd.com"
            case .northAmerica:
                return "na.lightwalletd.com"
            case .southAmerica:
                return "sa.lightwalletd.com"
            }
        }
        
        public var port: Int {
            switch self {
            case .`default`:
                9067
            case .asiaOceania,
                 .europeAfrica,
                 .northAmerica,
                 .southAmerica:
                443
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
        
        public var id: String { rawValue }
        
        public var label: String {
            switch self {
            case .`default`:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.default
            case .dark:
                L10n.Nighthawk.SettingsTab.Advanced.Theme.dark
            }
        }
        
        public var colorScheme: ColorScheme {
            switch self {
            case .`default`:
                .light
            case .dark:
                .dark
            }
        }
    }
}
