//
//  NighthawkBackground.swift
//  stealth
//

import Generated
import Models
import SwiftUI
import UIKit

private struct NighthawkSuppressNestedBackgroundKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// When true, `applyNighthawkBackground()` is skipped so nested home tab
    /// screens do not install full-screen backgrounds that block the tab bar.
    var nighthawkSuppressNestedBackground: Bool {
        get { self[NighthawkSuppressNestedBackgroundKey.self] }
        set { self[NighthawkSuppressNestedBackgroundKey.self] = newValue }
    }
}

/// Android `MainActivity` Cyberpunk wallpaper:
/// `ContentScale.Crop` + `Alignment.TopStart` over `#05060A`, then `#80050810` scrim.
///
/// Uses the same `cyberpunk_bg.jpg` as Android. The scaled image's top-left is
/// locked to this view's top-left (screen origin once `ignoresSafeArea` is set).
struct CyberpunkWallpaperView: UIViewRepresentable {
    func makeUIView(context: Context) -> CyberpunkWallpaperUIView {
        let view = CyberpunkWallpaperUIView()
        view.insetsLayoutMarginsFromSafeArea = false
        return view
    }

    func updateUIView(_ uiView: CyberpunkWallpaperUIView, context: Context) {}
}

final class CyberpunkWallpaperUIView: UIView {
    private let imageView = UIImageView()
    private let scrimView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = false
        insetsLayoutMarginsFromSafeArea = false
        backgroundColor = UIColor(CyberpunkPalette.backdrop)
        imageView.image = Asset.Assets.Backgrounds.cyberpunkBg.systemImage
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)

        scrimView.backgroundColor = UIColor(CyberpunkPalette.scrim)
        addSubview(scrimView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0 else {
            imageView.frame = .zero
            scrimView.frame = bounds
            return
        }
        // Cover the view, then pin the scaled bitmap's origin to (0, 0).
        // Matches Compose ContentScale.Crop + Alignment.TopStart.
        let scale = max(bounds.width / image.size.width, bounds.height / image.size.height)
        imageView.frame = CGRect(
            x: 0,
            y: 0,
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        scrimView.frame = bounds
    }
}

public struct NighthawkBackgroundModifier: ViewModifier {
    @Environment(\.nighthawkSuppressNestedBackground)
    private var suppressNestedBackground

    /// Reads the live Advanced-theme preference (Android `AppThemeVariant`).
    /// Key matches `UserPreferencesStorage.Constants.darkfiTheme`.
    private var resolvedTheme: NighthawkSetting.Theme {
        let raw = UserDefaults.standard.string(forKey: "darkfiTheme")
        return (NighthawkSetting.Theme(rawValue: raw ?? "") ?? .cyberpunk).canonical
    }

    private var usesCyberpunkWallpaper: Bool {
        resolvedTheme.usesCyberpunkWallpaper
    }

    private var solidBackdrop: Color {
        switch resolvedTheme {
        case .paper:
            return Color(red: 0xF7 / 255, green: 0xF8 / 255, blue: 0xFA / 255)
        case .light:
            return Color(red: 0xE8 / 255, green: 0xEA / 255, blue: 0xED / 255)
        case .midnight:
            return Color(red: 0x0A / 255, green: 0x08 / 255, blue: 0x14 / 255)
        case .stealth, .dark:
            return Color(red: 0x0E / 255, green: 0x10 / 255, blue: 0x12 / 255)
        case .cyberpunk, .`default`:
            return CyberpunkPalette.backdrop
        }
    }

    public func body(content: Content) -> some View {
        if suppressNestedBackground {
            content
        } else if usesCyberpunkWallpaper {
            ZStack {
                CyberpunkWallpaperView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false)
                content
            }
        } else {
            ZStack {
                solidBackdrop
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false)
                content
            }
        }
    }
}

public extension View {
    /// Theme-aware background. Cyberpunk uses the shared `cyberpunk_bg.jpg`
    /// wallpaper (top-left crop + scrim); other variants use solid fills.
    func applyNighthawkBackground() -> some View {
        self.modifier(NighthawkBackgroundModifier())
    }
}
