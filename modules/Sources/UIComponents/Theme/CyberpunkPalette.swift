//
//  CyberpunkPalette.swift
//
//  Android `CyberpunkColorPalette` + `CyberpunkExtendedColorPalette`
//  (default theme since testnet 3.00.027).
//

import SwiftUI

public enum CyberpunkPalette {
    /// `#5CE1FF` primary CTA and selected navigation.
    public static let primary = Color(red: 92 / 255, green: 225 / 255, blue: 255 / 255)
    /// `#041018` label on the cyan button.
    public static let onPrimary = Color(red: 4 / 255, green: 16 / 255, blue: 24 / 255)
    /// `#F7FBFF` titles.
    public static let header = Color(red: 247 / 255, green: 251 / 255, blue: 255 / 255)
    /// `#F4FBFF` body.
    public static let body = Color(red: 244 / 255, green: 251 / 255, blue: 255 / 255)
    /// `#D5DEEA` secondary text (`onSurfaceVariant`).
    public static let muted = Color(red: 213 / 255, green: 222 / 255, blue: 234 / 255)
    /// `#A8B2BD` splash tagline.
    public static let tagline = Color(red: 168 / 255, green: 178 / 255, blue: 189 / 255)
    /// `#C94BB8` wallpaper magenta for selection chrome.
    public static let reference = Color(red: 201 / 255, green: 75 / 255, blue: 184 / 255)
    /// `#FFD6F6` label on a selected chat chip.
    public static let chipLabel = Color(red: 255 / 255, green: 214 / 255, blue: 246 / 255)
    /// `#6B1A6B` at 38% — selected FilterChip container.
    public static let chipFill = Color(red: 107 / 255, green: 26 / 255, blue: 107 / 255).opacity(0.38)
    /// `#05060A` letterbox behind the wallpaper.
    public static let backdrop = Color(red: 5 / 255, green: 6 / 255, blue: 10 / 255)
    /// `#80050810` scrim so type stays readable.
    public static let scrim = Color(red: 5 / 255, green: 8 / 255, blue: 16 / 255).opacity(128 / 255)
    /// `#C010121C` translucent panel.
    public static let surface = Color(red: 16 / 255, green: 18 / 255, blue: 28 / 255).opacity(192 / 255)
    /// `#B8161C28` selected nav indicator / raised panel.
    public static let surfaceVariant = Color(red: 22 / 255, green: 28 / 255, blue: 40 / 255).opacity(184 / 255)
    /// `#C0050810` bottom bar, wallpaper still visible.
    public static let navigationContainer = Color(red: 5 / 255, green: 8 / 255, blue: 16 / 255).opacity(192 / 255)
    /// `#E7EEF8` unselected tab icon and label.
    public static let navigationIcon = Color(red: 231 / 255, green: 238 / 255, blue: 248 / 255)
    /// `#3D4C5C` dividers and outlines.
    public static let outline = Color(red: 61 / 255, green: 76 / 255, blue: 92 / 255)
    /// `#B8141824` tertiary button fill.
    public static let tertiaryFill = Color(red: 20 / 255, green: 24 / 255, blue: 36 / 255).opacity(184 / 255)
}
